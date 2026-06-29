package com.webnest.webnest.engine

import android.net.Uri
import java.io.BufferedReader
import java.io.InputStream
import java.io.InputStreamReader
import java.io.File

/**
 * WebNest Shield Engine — Adblock Plus–compatible filter rule engine.
 *
 * Upgrades from V1 (hardcoded domain list) to a full rule loader that parses
 * Adblock Plus filter list syntax (.txt format).
 *
 * Supported rule types:
 *  - `||domain.com^`        → block all requests to this domain
 *  - `||domain.com/path^`   → block requests matching prefix
 *  - `@@||domain.com^`      → whitelist / exception rule
 *  - Lines starting with `!` → comments (skipped)
 *  - Lines starting with `[` → section headers (skipped)
 *  - Cosmetic rules (`##`)  → skipped (JS injection not supported in this version)
 *
 * Filter lists are loaded from files downloaded by FilterListManager on the Dart side.
 * No filter content is bundled in the APK.
 */
object WebNestShieldEngine {

    // ── Rule storage ──────────────────────────────────────────────────────────

    /** Exact domain block rules: `||domain.com^` */
    private val blockedDomains = HashSet<String>()
    private val blockedPrefixes = HashMap<String, ArrayList<String>>()
    private val blockedWildcards = HashMap<String, ArrayList<Regex>>()
    private val blockedExact = ArrayList<String>()

    /** Exception / whitelist rules */
    private val allowedDomains = HashSet<String>()
    private val allowedPrefixes = HashMap<String, ArrayList<String>>()
    private val allowedWildcards = HashMap<String, ArrayList<Regex>>()
    private val allowedExact = ArrayList<String>()

    // ── Synchronization ───────────────────────────────────────────────────────

    private val lock = Any()

    // ── Rule loading ──────────────────────────────────────────────────────────

    fun clearRules() {
        synchronized(lock) {
            blockedDomains.clear()
            blockedPrefixes.clear()
            blockedWildcards.clear()
            blockedExact.clear()
            allowedDomains.clear()
            allowedPrefixes.clear()
            allowedWildcards.clear()
            allowedExact.clear()
        }
    }

    fun getRuleCount(): Int {
        return synchronized(lock) {
            blockedDomains.size + blockedPrefixes.values.sumOf { it.size } +
            blockedWildcards.values.sumOf { it.size } + blockedExact.size
        }
    }

    fun loadFromFile(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false
            file.inputStream().use { stream ->
                loadFromStream(stream)
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun loadFromStream(inputStream: InputStream) {
        val reader = BufferedReader(InputStreamReader(inputStream, Charsets.UTF_8))
        val newDomains = HashSet<String>()
        val newPrefixes = HashMap<String, ArrayList<String>>()
        val newWildcards = HashMap<String, ArrayList<Regex>>()
        val newExact = ArrayList<String>()
        
        val newAllowedDomains = HashSet<String>()
        val newAllowedPrefixes = HashMap<String, ArrayList<String>>()
        val newAllowedWildcards = HashMap<String, ArrayList<Regex>>()
        val newAllowedExact = ArrayList<String>()

        reader.use { r ->
            r.forEachLine { rawLine ->
                val line = rawLine.trim()
                parseRule(
                    line,
                    newDomains, newPrefixes, newWildcards, newExact,
                    newAllowedDomains, newAllowedPrefixes, newAllowedWildcards, newAllowedExact
                )
            }
        }

        synchronized(lock) {
            blockedDomains.addAll(newDomains)
            for ((k, v) in newPrefixes) blockedPrefixes.getOrPut(k) { ArrayList() }.addAll(v)
            for ((k, v) in newWildcards) blockedWildcards.getOrPut(k) { ArrayList() }.addAll(v)
            blockedExact.addAll(newExact)
            
            allowedDomains.addAll(newAllowedDomains)
            for ((k, v) in newAllowedPrefixes) allowedPrefixes.getOrPut(k) { ArrayList() }.addAll(v)
            for ((k, v) in newAllowedWildcards) allowedWildcards.getOrPut(k) { ArrayList() }.addAll(v)
            allowedExact.addAll(newAllowedExact)
        }
    }

    private fun parseRule(
        line: String,
        domains: HashSet<String>,
        prefixes: HashMap<String, ArrayList<String>>,
        wildcards: HashMap<String, ArrayList<Regex>>,
        exact: ArrayList<String>,
        allowedDomains: HashSet<String>,
        allowedPrefixes: HashMap<String, ArrayList<String>>,
        allowedWildcards: HashMap<String, ArrayList<Regex>>,
        allowedExact: ArrayList<String>
    ) {
        if (line.isEmpty() || line.startsWith('!') || line.startsWith('[') ||
            line.contains("##") || line.contains("#@#") || line.contains("#?#")
        ) return

        val isException = line.startsWith("@@")
        val rule = if (isException) line.substring(2) else line

        // FATAL FLAW FIX: If a rule (block or exception) is restricted to a specific domain (e.g. $domain=...)
        // and we strip it, we globally apply it! For exceptions, it whitelists ads. For blocks, it blocks the whole internet!
        // So we MUST ignore domain-restricted rules completely.
        if (rule.contains("domain=")) return

        // 1. Strip options
        val optionsIdx = rule.lastIndexOf('$')
        val ruleWithoutOptions = if (optionsIdx != -1) rule.substring(0, optionsIdx) else rule

        // 2. Drop broad exceptions or blocks that break the adblocker when options are ignored
        if (ruleWithoutOptions.contains('*') && ruleWithoutOptions.length < 10) return
        if (ruleWithoutOptions.startsWith("|http") && ruleWithoutOptions.length < 14) return

        // 3. Strip trailing ^
        val cleanRule = if (ruleWithoutOptions.endsWith("^")) ruleWithoutOptions.dropLast(1) else ruleWithoutOptions

        if (cleanRule.isEmpty()) return

        if (cleanRule.startsWith("||")) {
            val body = cleanRule.substring(2)
            if (body.isEmpty() || body == "*") return // Ignore overly broad rules
            
            val slashIdx = body.indexOf('/')
            val starIdx = body.indexOf('*')
            
            val isDomainOnly = slashIdx == -1 || slashIdx == body.length - 1
            
            if (starIdx != -1) {
                // Rule contains a wildcard
                val domainPart = if (slashIdx != -1 && starIdx > slashIdx) body.substring(0, slashIdx).lowercase() else ""
                val regexPattern = "^" + Regex.escape(body).replace("\\*", ".*")
                try {
                    val regex = Regex(regexPattern, RegexOption.IGNORE_CASE)
                    if (domainPart.isNotEmpty()) {
                        if (isException) allowedWildcards.getOrPut(domainPart) { ArrayList() }.add(regex)
                        else wildcards.getOrPut(domainPart) { ArrayList() }.add(regex)
                    } else {
                        // Global wildcard (no clear domain), assign to empty string key
                        if (isException) allowedWildcards.getOrPut("") { ArrayList() }.add(regex)
                        else wildcards.getOrPut("") { ArrayList() }.add(regex)
                    }
                } catch (_: Exception) {}
            } else {
                val normalizedRule = body.trimEnd('/').lowercase()
                if (isDomainOnly) {
                    if (!normalizedRule.contains('.')) return // FATAL FLAW FIX: Do not block entire TLDs like "com" or "net"
                    if (isException) allowedDomains.add(normalizedRule)
                    else domains.add(normalizedRule)
                } else {
                    val domainPart = body.substring(0, slashIdx).lowercase()
                    if (isException) allowedPrefixes.getOrPut(domainPart) { ArrayList() }.add(normalizedRule)
                    else prefixes.getOrPut(domainPart) { ArrayList() }.add(normalizedRule)
                }
            }
        } else if (cleanRule.startsWith("|http")) {
            val body = cleanRule.substring(1) // remove leading '|'
            if (isException) allowedExact.add(body.lowercase())
            else exact.add(body.lowercase())
        }
    }

    // ── Request filtering ─────────────────────────────────────────────────────

    fun shouldBlockRequest(url: String?): String? {
        if (url == null) return null
        return try {
            val uri = Uri.parse(url)
            val host = uri.host?.lowercase() ?: return null
            val schemePos = url.indexOf("://")
            val fullUrl = if (schemePos != -1) url.substring(schemePos + 3).lowercase() else url.lowercase()
            val exactUrl = url.lowercase()

            synchronized(lock) {
                if (isAllowed(host, fullUrl, exactUrl)) return null
                isBlocked(host, fullUrl, exactUrl)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun isAllowed(host: String, fullUrl: String, exactUrl: String): Boolean {
        if (allowedDomains.isEmpty() && allowedPrefixes.isEmpty() && allowedWildcards.isEmpty() && allowedExact.isEmpty()) return false
        if (matchesDomain(host, allowedDomains) != null) return true
        if (matchesPrefixes(host, fullUrl, allowedPrefixes) != null) return true
        if (matchesWildcards(host, fullUrl, allowedWildcards) != null) return true
        if (allowedExact.any { exactUrl.startsWith(it) }) return true
        return false
    }

    private fun isBlocked(host: String, fullUrl: String, exactUrl: String): String? {
        matchesDomain(host, blockedDomains)?.let { return "Domain: $it" }
        matchesPrefixes(host, fullUrl, blockedPrefixes)?.let { return "Prefix: $it" }
        matchesWildcards(host, fullUrl, blockedWildcards)?.let { return "Wildcard: $it" }
        blockedExact.firstOrNull { exactUrl.startsWith(it) }?.let { return "Exact: $it" }
        return null
    }

    private fun matchesDomain(host: String, domainSet: HashSet<String>): String? {
        var current = host
        while (current.isNotEmpty()) {
            if (domainSet.contains(current)) return current
            val dotIdx = current.indexOf('.')
            if (dotIdx != -1 && dotIdx < current.length - 1) {
                current = current.substring(dotIdx + 1)
            } else break
        }
        return null
    }

    private fun matchesPrefixes(
        host: String,
        fullUrl: String,
        prefixMap: HashMap<String, ArrayList<String>>
    ): String? {
        var current = host
        while (current.isNotEmpty()) {
            val list = prefixMap[current]
            if (list != null) {
                val match = list.firstOrNull { fullUrl.startsWith(it) }
                if (match != null) return match
            }
            val dotIdx = current.indexOf('.')
            if (dotIdx != -1 && dotIdx < current.length - 1) {
                current = current.substring(dotIdx + 1)
            } else break
        }
        return null
    }
    
    private fun matchesWildcards(
        host: String,
        fullUrl: String,
        wildcardMap: HashMap<String, ArrayList<Regex>>
    ): String? {
        // Check global wildcards
        val globals = wildcardMap[""]
        if (globals != null) {
            val match = globals.firstOrNull { it.containsMatchIn(fullUrl) }
            if (match != null) return match.pattern
        }
        
        var current = host
        while (current.isNotEmpty()) {
            val list = wildcardMap[current]
            if (list != null) {
                val match = list.firstOrNull { it.containsMatchIn(fullUrl) }
                if (match != null) return match.pattern
            }
            val dotIdx = current.indexOf('.')
            if (dotIdx != -1 && dotIdx < current.length - 1) {
                current = current.substring(dotIdx + 1)
            } else break
        }
        return null
    }
}
