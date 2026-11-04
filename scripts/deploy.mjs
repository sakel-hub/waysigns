/**
 * Deploy code to ContentDB
 * Copyright (C) 2026 SaKeL
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see <https://www.gnu.org/licenses/>.
 */

import fs from 'node:fs'
import path from 'node:path'
import https from 'node:https'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

// Resolve .env relative to script directory and cwd
const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const envPaths = [
    path.resolve(scriptDir, '../.env'),
    path.resolve(process.cwd(), '.env')
]

for (const envPath of envPaths) {
    if (fs.existsSync(envPath)) {
        try {
            const envContent = fs.readFileSync(envPath, 'utf8')
            for (const line of envContent.split('\n')) {
                const trimmed = line.trim()
                if (!trimmed || trimmed.startsWith('#')) continue
                const eqIdx = trimmed.indexOf('=')
                if (eqIdx !== -1) {
                    const key = trimmed.slice(0, eqIdx).trim()
                    const val = trimmed.slice(eqIdx + 1).trim().replace(/^['"](.*)['"]$/, '$1')
                    if (!process.env[key] && val) {
                        process.env[key] = val
                    }
                }
            }
        } catch (_) {}
    }
}

// Parse CLI arguments with yargs (or fallback parser)
let argv = {}
try {
    const yargsMod = (await import('yargs/yargs')).default
    const { hideBin } = await import('yargs/helpers')
    argv = yargsMod(hideBin(process.argv)).argv
} catch (_) {
    const rawArgs = process.argv.slice(2)
    for (let i = 0; i < rawArgs.length; i++) {
        const arg = rawArgs[i]
        if (arg.startsWith('--')) {
            const eqIdx = arg.indexOf('=')
            if (eqIdx !== -1) {
                argv[arg.slice(2, eqIdx)] = arg.slice(eqIdx + 1)
            } else if (i + 1 < rawArgs.length && !rawArgs[i + 1].startsWith('--')) {
                argv[arg.slice(2)] = rawArgs[++i]
            } else {
                argv[arg.slice(2)] = true
            }
        }
    }
}

// HTTPS fallback request helper
function requestHttps(url, options, bodyData) {
    return new Promise((resolve, reject) => {
        const u = new URL(url)
        const headers = Object.assign({
            'User-Agent': 'node-deploy-script/1.0 (SaKeL)'
        }, options.headers || {})
        if (bodyData) {
            headers['Content-Length'] = Buffer.byteLength(bodyData)
        }
        const req = https.request({
            hostname: u.hostname,
            path: u.pathname + u.search,
            method: options.method || 'GET',
            headers: headers
        }, (res) => {
            let data = ''
            res.on('data', chunk => { data += chunk })
            res.on('end', () => {
                let parsed
                try {
                    parsed = JSON.parse(data)
                } catch (_) {
                    parsed = data
                }
                resolve({
                    ok: res.statusCode >= 200 && res.statusCode < 300,
                    status: res.statusCode,
                    json: async () => parsed
                })
            })
        })
        req.on('error', reject)
        if (bodyData) {
            req.write(bodyData)
        }
        req.end()
    })
}

// Resolve fetch implementation
let fetchFn = globalThis.fetch
if (!fetchFn) {
    try {
        fetchFn = (await import('node-fetch')).default
    } catch (_) {}
}
if (!fetchFn) {
    fetchFn = (url, opts) => requestHttps(url, opts, opts.body)
}

try {
    const token = process.env.CONTENT_DB_WAYSIGNS_TOKEN || process.env.CONTENTDB_TOKEN || process.env.CONTENT_DB_TOKEN || argv.token
    if (!token) {
        console.error('Error: Missing ContentDB token! Provide CONTENT_DB_WAYSIGNS_TOKEN or pass --token=<token>.')
        process.exit(1)
    }

    const title = argv.title ?? argv.tag
    if (!title) {
        console.error('Error: Missing release title/tag! Pass --title=<title> or --tag=<tag>.')
        process.exit(1)
    }

    const ref = argv.ref ?? title ?? 'main'

    const body = {
        method: 'git',
        title: title,
        ref: ref
    }

    console.log('Submitting release to ContentDB for SaKeL/waysigns:', body)

    const response = await fetchFn('https://content.luanti.org/api/packages/SaKeL/waysigns/releases/new/', {
        method: 'POST',
        body: JSON.stringify(body),
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`
        }
    })
    const data = await response.json()

    console.log('ContentDB API response:', data)

    // Handle ContentDB fallback when git creation is disabled
    if (data && data.error && typeof data.error === 'string' && data.error.includes('upload a .zip file instead')) {
        console.log('Git method disabled by ContentDB, packaging and uploading zip archive...')
        const zipPath = path.resolve('/tmp', `waysigns-${title}.zip`)
        try {
            const gitArch = spawnSync('git', ['archive', '-o', zipPath, String(ref)], { stdio: 'inherit' })
            if (gitArch.status !== 0) {
                console.error('git archive failed')
                process.exit(1)
            }
            let commitSha = ''
            const gitSha = spawnSync('git', ['rev-parse', String(ref)], { encoding: 'utf8' })
            if (gitSha.status === 0 && gitSha.stdout) {
                commitSha = gitSha.stdout.trim()
            }

            const curlArgs = [
                '-s', '-S', '-X', 'POST',
                'https://content.luanti.org/api/packages/SaKeL/waysigns/releases/new/',
                '-H', `Authorization: Bearer ${token}`,
                '-F', `title=${title}`,
                ...(commitSha && commitSha.length === 40 ? ['-F', `commit=${commitSha}`] : []),
                '-F', `file=@${zipPath}`
            ]

            const curlRun = spawnSync('curl', curlArgs, { encoding: 'utf8' })
            if (curlRun.status !== 0) {
                console.error('Curl execution failed:', curlRun.stderr)
                process.exit(1)
            }

            let curlJson
            try {
                curlJson = JSON.parse(curlRun.stdout)
            } catch (_) {
                curlJson = { raw: curlRun.stdout }
            }

            console.log('ContentDB Zip Upload API response:', curlJson)
            if (!curlJson.success) {
                console.error('ContentDB zip deployment failed:', curlJson)
                process.exit(1)
            }

            console.log(`Successfully deployed ${title} to ContentDB via zip upload!`)
            process.exit(0)
        } finally {
            if (fs.existsSync(zipPath)) {
                try { fs.unlinkSync(zipPath) } catch (_) {}
            }
        }
    }

    if (!response.ok || (data.success !== undefined && !data.success)) {
        console.error('ContentDB deployment failed:', data)
        process.exit(1)
    }

    console.log(`Successfully deployed ${title} to ContentDB!`)
} catch (error) {
    console.error('Deployment error:', error)
    process.exit(1)
}
