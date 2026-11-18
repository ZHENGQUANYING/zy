import { spawn } from 'node:child_process'
import { createServer } from 'node:net'

const npmCommand = process.platform === 'win32' ? 'npm.cmd' : 'npm'

function findPort(port) {
  return new Promise((resolve) => {
    const server = createServer()
    server.once('error', () => findPort(port + 1).then(resolve))
    server.listen(port, '127.0.0.1', () => server.close(() => resolve(port)))
  })
}

const port = await findPort(5173)
const spawnOptions = {
  stdio: 'inherit',
  shell: process.platform === 'win32',
}
const vite = spawn(npmCommand, ['run', 'dev', '--', '--host', '127.0.0.1', '--port', String(port)], spawnOptions)
const devUrl = `http://127.0.0.1:${port}`

async function waitForServer(url) {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      await fetch(url)
      return
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 250))
    }
  }
  throw new Error(`Vite did not start at ${url}`)
}

await waitForServer(devUrl)
const electron = spawn(npmCommand, ['exec', '--', 'electron', '.'], {
  env: { ...process.env, VITE_DEV_SERVER_URL: devUrl },
  ...spawnOptions,
})

function stop() {
  vite.kill()
  electron.kill()
}

process.on('SIGINT', stop)
process.on('SIGTERM', stop)
electron.on('exit', (code) => {
  stop()
  process.exit(code ?? 0)
})
