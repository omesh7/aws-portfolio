import { GetObjectCommand } from "@aws-sdk/client-s3";
import { parse } from "csv-parse/sync";
import { streamToString } from "./stream";
import { s3 } from "./awsClients";
import { log } from "./logger";
import { Readable } from "node:stream";

const { S3_BUCKET, CSV_FILE } = process.env;

export const getEmails = async (): Promise<string[]> => {
  try 
    log.info(`Fetching CSV from S3: ${S3_BUCKET}/${CSV_FILE}`);
    const data = await s3.send(
      new GetObjectCommand({
        Bucket: S3_BUCKET!,
        Key: CSV_FILE!,
      })
    );
    const csvText = await streamToString(data.Body as Readable);
    const records = parse(csvText, { columns: true });
    return records.map((r: any) => r.email).filter(Boolean);
  } catch (err) {
    log.error("Failed to get emails from S3", err);
    return [];
  }
};
