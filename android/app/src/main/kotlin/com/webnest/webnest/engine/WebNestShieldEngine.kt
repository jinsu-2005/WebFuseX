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

    /** Prefix URL block rules: `||domain.com/path` — stored as normalized strings */
    private val blockedPrefixes = ArrayList<String>()

    /** Exception / whitelist rules: `@@||domain.com^` */
    private val allowedDomains = HashSet<String>()
    private val allowedPrefixes = ArrayList<String>()

    // ── Synchronization ───────────────────────────────────────────────────────

    private val lock = Any()

    // ── Rule loading ──────────────────────────────────────────────────────────

    /**
     * Clears all loaded rules. Call before reloading a fresh set of lists.
     */
    fun clearRules() {
        synchronized(lock) {
            blockedDomains.clear()
            blockedPrefixes.clear()
            allowedDomains.clear()
            allowedPrefixes.clear()
        }
    }

    /**
     * Returns the total number of blocking rules currently loaded.
     */
    fun getRuleCount(): Int {
        return synchronized(lock) {
            blockedDomains.size + blockedPrefixes.size
        }
    }

    /**
     * Loads and parses filter rules from a file path.
     * Can be called multiple times to load multiple lists.
     */
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

    /**
     * Loads and parses filter rules from an InputStream.
     */
    fun loadFromStream(inputStream: InputStream) {
        val reader = BufferedReader(InputStreamReader(inputStream, Charsets.UTF_8))
        val newDomains = HashSet<String>()
        val newPrefixes = ArrayList<String>()
        val newAllowedDomains = HashSet<String>()
        val newAllowedPrefixes = ArrayList<String>()

        reader.use { r ->
            r.forEachLine { rawLine ->
                val line = rawLine.trim()
                parseRule(
                    line,
                    newDomains,
                    newPrefixes,
                    newAllowedDomains,
                    newAllowedPrefixes,
                )
            }
        }

        synchronized(lock) {
            blockedDomains.addAll(newDomains)
            blockedPrefixes.addAll(newPrefixes)
            allowedDomains.addAll(newAllowedDomains)
            allowedPrefixes.addAll(newAllowedPrefixes)
        }
    }

    private fun parseRule(
        line: String,
        domains: HashSet<String>,
        prefixes: ArrayList<String>,
        allowedDomains: HashSet<String>,
        allowedPrefixes: ArrayList<String>,
    ) {
        // Skip blank lines, comments, section headers, and cosmetic rules
        if (line.isEmpty() || line.startsWith('!') || line.startsWith('[') ||
            line.contains("##") || line.contains("#@#") || line.contains("#?#")
        ) return

        val isException = line.startsWith("@@")
        val rule = if (isException) line.substring(2) else line

        // Only handle `||` anchor rules for now (most impactful)
        if (!rule.startsWith("||")) return

        val body = rule.substring(2) // strip `||`

        // Determine if it ends with `^` (pure domain or domain+path)
        val cleanBody = if (body.endsWith("^")) body.dropLast(1) else body
        val options = if (cleanBody.contains('$')) {
            val idx = cleanBody.lastIndexOf('$')
            cleanBody.substring(idx + 1)
        } else ""

        // Strip option suffix
        val urlPart = if (cleanBody.contains('$')) {
            cleanBody.substring(0, cleanBody.lastIndexOf('$'))
        } else cleanBody

        // Check for domain-only rule (no path component after the domain)
        val slashIdx = urlPart.indexOf('/')
        val isDomainOnly = slashIdx == -1 || slashIdx == urlPart.length - 1

        val normalizedRule = urlPart.trimEnd('/').lowercase()

        if (isDomainOnly) {
            // Pure domain block/allow: `||example.com^`
            if (isException) allowedDomains.add(normalizedRule)
            else domains.add(normalizedRule)
        } else {
            // URL prefix: `||example.com/path/to/ads`
            if (isException) allowedPrefixes.add(normalizedRule)
            else prefixes.add(normalizedRule)
        }
    }

    // ── Request filtering ─────────────────────────────────────────────────────

    /**
     * Returns true if the request URL should be blocked.
     *
     * Check order:
     *  1. If URL matches an exception (@@) rule → allow.
     *  2. If URL matches a block rule → block.
     *  3. Otherwise → allow.
     */
    fun shouldBlockRequest(url: String?): Boolean {
        if (url == null) return false
        return try {
            val uri = Uri.parse(url)
            val host = uri.host?.lowercase() ?: return false
            val path = uri.path?.lowercase() ?: ""
            val fullUrl = "$host$path"

            synchronized(lock) {
                // Check exceptions first
                if (isAllowed(host, fullUrl)) return false
                // Then check block rules
                isBlocked(host, fullUrl)
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun isAllowed(host: String, fullUrl: String): Boolean {
        if (allowedDomains.isEmpty() && allowedPrefixes.isEmpty()) return false
        if (matchesDomain(host, allowedDomains)) return true
        return allowedPrefixes.any { fullUrl.startsWith(it) }
    }

    private fun isBlocked(host: String, fullUrl: String): Boolean {
        if (matchesDomain(host, blockedDomains)) return true
        return blockedPrefixes.any { fullUrl.startsWith(it) }
    }

    /**
     * Checks if [host] or any of its parent domains are in [domainSet].
     * e.g. "ads.example.com" will match "example.com" in the set.
     */
    private fun matchesDomain(host: String, domainSet: HashSet<String>): Boolean {
        var current = host
        while (current.isNotEmpty()) {
            if (domainSet.contains(current)) return true
            val dotIdx = current.indexOf('.')
            if (dotIdx != -1 && dotIdx < current.length - 1) {
                current = current.substring(dotIdx + 1)
            } else {
                break
            }
        }
        return false
    }
}
