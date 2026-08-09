import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { createServer, request as httpRequest } from 'node:http';
import { extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const port = Number(process.env.PORT ?? 8080);
const apiHost = process.env.API_HOST ?? '127.0.0.1';
const apiPort = Number(process.env.API_PORT ?? 3000);
const projectRoot = resolve(fileURLToPath(new URL('..', import.meta.url)));
const webRoot = join(projectRoot, 'build', 'web');
const types = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.jpg': 'image/jpeg',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.webp': 'image/webp',
};

createServer(async (request, response) => {
  const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);

  if (pathname === '/api/v1' || pathname.startsWith('/api/v1/')) {
    const proxyRequest = httpRequest(
      {
        host: apiHost,
        port: apiPort,
        method: request.method,
        path: request.url,
        headers: { ...request.headers, host: `${apiHost}:${apiPort}` },
      },
      (proxyResponse) => {
        response.writeHead(proxyResponse.statusCode ?? 502, proxyResponse.headers);
        proxyResponse.pipe(response);
      },
    );

    proxyRequest.on('error', () => {
      if (response.headersSent) return response.end();
      response.writeHead(502, { 'Content-Type': 'application/json; charset=utf-8' });
      response.end(JSON.stringify({
        message: 'La API de AsisteQR Baker no está disponible.',
        statusCode: 502,
      }));
    });
    request.pipe(proxyRequest);
    return;
  }

  const relative = normalize(pathname).replace(/^(\.\.(\/|\\|$))+/, '').replace(/^[/\\]+/, '');
  let file = join(webRoot, relative || 'index.html');

  try {
    if ((await stat(file)).isDirectory()) file = join(file, 'index.html');
  } catch {
    file = join(webRoot, 'index.html');
  }

  response.writeHead(200, {
    'Cache-Control': 'no-store, no-cache, must-revalidate',
    'Content-Type': types[extname(file)] ?? 'application/octet-stream',
    Expires: '0',
    Pragma: 'no-cache',
  });
  createReadStream(file).pipe(response);
}).listen(port, '0.0.0.0', () => {
  process.stdout.write(`AsisteQR Baker web disponible en http://0.0.0.0:${port}\n`);
});
