import { Readable } from 'stream'

export const streamToString = (stream: Readable): Promise<string> =>
    new Promise((resolve, reject) => {
        const chunks: any[] = []
        stream.on('data', chunk => chunks.push(chunk))
        stream.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')))
        stream.on('error', reject)
    })
