import pandas as pd
import time

INPUT_CSV  = "spotify_100k_trimmed_parallel.csv"
OUTPUT_CSV = "songs_for_personalize.csv"

# Map from your original columns to the uppercase schema names
RENAME_MAP = {
    "Artist(s)": "artist",            # keep for metadata
    "song": "song",
    "Length": "length",
    "Genre": "genre",
    "Release Date": "creation_timestamp",
    "Tempo": "tempo",
    "Loudness (db)": "loudness",
    "Popularity": "popularity",
    "Energy": "energy",
    "Danceability": "danceability",
    "Positiveness": "positiveness",
    "Speechiness": "speechiness",
    "Liveness": "liveness",
    "Acousticness": "acousticness",
    "Instrumentalness": "instrumentalness",
    "Good for Work/Study": "good_for_work",
    "Good for Relaxation/Meditation": "good_for_relax",
    # on purpose, dropping text, Similar Artist/Song/Similarity, explicit etc.
}

# Define final schema-friendly column headers
SCHEMA_COLS = ["ITEM_ID", "GENRE", "CREATION_TIMESTAMP", "LENGTH",
               "TEMPO", "LOUDNESS", "POPULARITY", "ENERGY",
               "DANCEABILITY", "POSITIVENESS", "SPEECHINESS",
               "LIVENESS", "ACOUSTICNESS", "INSTRUMENTALNESS",
               "GOOD_FOR_WORK", "GOOD_FOR_RELAX",
               "ARTIST", "SONG"]

CHUNK = 10000
first = True

for chunk in pd.read_csv(INPUT_CSV, chunksize=CHUNK):
    # Assume there's an 'ITEM_ID' column; else derive from index
    df = chunk.rename(columns=RENAME_MAP)
    # Convert release date to UNIX epoch
    if "creation_timestamp" in df:
        df["creation_timestamp"] = pd.to_datetime(df["creation_timestamp"]).astype(int) // 10**9

    # Select only columns we want
    df = df[list(RENAME_MAP.values()) + ["ITEM_ID"]].dropna(subset=["ITEM_ID"])

    # Rename lowercase columns to uppercase schema
    df = df.rename(columns={
        "creation_timestamp":"CREATION_TIMESTAMP",
        "length":"LENGTH",
        "tempo":"TEMPO",
        "loudness":"LOUDNESS",
        "popularity":"POPULARITY",
        "energy":"ENERGY",
        "danceability":"DANCEABILITY",
        "positiveness":"POSITIVENESS",
        "speechiness":"SPEECHINESS",
        "liveness":"LIVENESS",
        "acousticness":"ACOUSTICNESS",
        "instrumentalness":"INSTRUMENTALNESS",
        "good_for_work":"GOOD_FOR_WORK",
        "good_for_relax":"GOOD_FOR_RELAX",
        "artist":"ARTIST",
        "song":"SONG",
    })

    df = df[["ITEM_ID"] + SCHEMA_COLS[1:]]
    df.to_csv(OUTPUT_CSV, mode="w" if first else "a", index=False, header=first)
    first = False

print("✅ CSV trimmed and schema-aligned ready for upload to S3.")
