"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.streamToString = void 0;
const streamToString = (stream) => new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', chunk => chunks.push(chunk));
    stream.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    stream.on('error', reject);
});
exports.streamToString = streamToString;
