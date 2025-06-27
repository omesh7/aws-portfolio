import pandas as pd
import dask.dataframe as dd
import os
import time

def prepare_spotify_for_personalize(input_filename="spotify_100k_dataset.csv", output_filename="spotify_personalize_items.csv", num_rows_to_keep=100000):
    """
    Reads a large Spotify CSV file using Dask for parallel and out-of-core processing.
    It selects a random sample of N rows (if input is raw), or processes the entire
    input file (if input is pre-trimmed), renames and selects columns to match
    AWS Personalize ITEMS schema requirements, converts 'Release Date' to epoch timestamp,
    and saves the processed data to a new CSV file.

    Args:
        input_filename (str): The name of the input CSV file.
        output_filename (str): The name of the output CSV file for the Personalize ITEMS dataset.
        num_rows_to_keep (int): The number of random rows to select from the file.
                                If the input_filename is already a trimmed dataset, set this
                                to a very large number (e.g., 1000000) to process all rows.
    """
    print(f"Starting data preparation for AWS Personalize from '{input_filename}'.")
    print(f"Processing columns and formatting for Personalize schema.")
    print("This script uses Dask for efficient handling of large datasets.")

    # --- 1. File Existence Check ---
    if not os.path.exists(input_filename):
        print(f"Error: The input file '{input_filename}' was not found in the current directory.")
        print("Please ensure the CSV file is in the same directory as this script, or provide its full path.")
        return

    try:
        start_time = time.time()

        # --- 2. Read CSV with Dask ---
        # Dask reads lazily, in chunks (blocksize), which is memory-efficient for large files.
        # 'low_memory=False' helps prevent mixed-type column warnings for large files.
        ddf = dd.read_csv(input_filename, low_memory=False, blocksize=25e6)
        print(f"Successfully created Dask DataFrame for '{input_filename}'.")

        # --- 3. Determine Total Rows (Dask computation) ---
        total_rows = len(ddf)
        print(f"Total rows in '{input_filename}': {total_rows}.")

        # --- 4. Handle Sampling Logic (or process all if input is already trimmed) ---
        # If the input file is already trimmed, we want to process all its rows.
        # We assume this by setting num_rows_to_keep to a large value when calling the function
        # such that total_rows < num_rows_to_keep condition is met.
        if total_rows <= num_rows_to_keep: # Changed to <= to handle exact matches gracefully
            print(f"Processing all {total_rows} rows from the input file as it's assumed to be pre-trimmed or smaller than target sample size.")
            # If the file is smaller than or equal to the desired 'sample' size, take all rows.
            df_processed = ddf.compute()
        else:
            # Calculate the fraction of rows to sample.
            frac_to_sample = num_rows_to_keep / total_rows

            print(f"Sampling {frac_to_sample:.4f} fraction of the dataset randomly...")
            df_sampled = ddf.sample(frac=frac_to_sample, random_state=None)

            print("Converting Dask DataFrame to Pandas DataFrame and computing sample...")
            df_processed = df_sampled.compute()

            # Dask's sample with 'frac' might not yield *exactly* `num_rows_to_keep` rows.
            # To ensure the exact number, we perform a final sample if needed.
            if len(df_processed) > num_rows_to_keep:
                print(f"Adjusting sample size from {len(df_processed)} to exact {num_rows_to_keep} rows.")
                df_processed = df_processed.sample(n=num_rows_to_keep, random_state=None).reset_index(drop=True)
            elif len(df_processed) < num_rows_to_keep:
                 print(f"Note: Dask's sampling resulted in {len(df_processed)} rows, which is less than the target {num_rows_to_keep}. Proceeding with the available sample.")


        # --- 5. Column Selection and Renaming for AWS Personalize ITEMS Schema ---
        column_mapping = {
            'song': 'ITEM_ID',
            'Artist(s)': 'ARTISTS',
            'text': 'DESCRIPTION',
            'Length': 'DURATION_MS', # Assuming Length is in milliseconds
            'emotion': 'EMOTION',
            'Genres': 'GENRES',
            'Album': 'ALBUM',
            'Release Date': 'CREATION_TIMESTAMP', # Will be converted to epoch seconds
            'Key': 'MUSICAL_KEY',
            'Tempo': 'TEMPO_BPM',
            'Loudness (db)': 'LOUDNESS_DB',
            'Time signature': 'TIME_SIGNATURE',
            'Explicit': 'EXPLICIT_CONTENT', # Boolean/categorical
            'Popularity': 'POPULARITY_SCORE', # Numerical score
            'Energy': 'ENERGY',
            'Danceability': 'DANCEABILITY',
            'Positiveness': 'POSITIVENESS',
            'Speechiness': 'SPEECHINESS',
            'Liveness': 'LIVENESS',
            'Acousticness': 'ACOUSTICNESS',
            'Instrumentalness': 'INSTRUMENTALNESS',
            'Good for Party': 'TAG_PARTY',
            'Good for Work/Study': 'TAG_WORK_STUDY',
            'Good for Relaxation/Meditation': 'TAG_RELAXATION_MEDITATION',
            'Good for Exercise': 'TAG_EXERCISE',
            'Good for Running': 'TAG_RUNNING',
            'Good for Yoga/Stretching': 'TAG_YOGA_STRETCHING',
            'Good for Driving': 'TAG_DRIVING',
            'Good for Social Gatherings': 'TAG_SOCIAL_GATHERINGS',
            'Good for Morning Routine': 'TAG_MORNING_ROUTINE'
        }

        # Identify columns present in the DataFrame that are in our mapping
        available_columns = [col for col in column_mapping if col in df_processed.columns]
        
        # Select only the available columns from the DataFrame
        df_selected = df_processed[available_columns]
        
        # Rename columns
        df_selected = df_selected.rename(columns=column_mapping)
        print("Columns selected and renamed for Personalize schema.")
        print(f"Final columns: {df_selected.columns.tolist()}")

        # --- 6. Data Type Conversion and Cleaning ---

        # Convert 'CREATION_TIMESTAMP' (formerly 'Release Date') to epoch seconds (Unix timestamp).
        # Personalize requires timestamps in Unix epoch seconds.
        if 'CREATION_TIMESTAMP' in df_selected.columns:
            # Convert to datetime, coercing errors will set invalid dates to NaT (Not a Time)
            df_selected['CREATION_TIMESTAMP'] = pd.to_datetime(df_selected['CREATION_TIMESTAMP'], errors='coerce')
            
            # Convert to Unix epoch time (seconds since 1970-01-01).
            # The previous error "Converting from datetime64[ns] to int32 is not supported. Do obj.astype('int64').astype(dtype) instead"
            # is fixed by explicitly casting to 'int64' first.
            df_selected['CREATION_TIMESTAMP'] = df_selected['CREATION_TIMESTAMP'].astype('int64') // 10**9 # Convert nanoseconds to seconds
            df_selected['CREATION_TIMESTAMP'] = df_selected['CREATION_TIMESTAMP'].fillna(0).astype(int) # Fill NaNs (from NaT) with 0 and convert to int
            print("Converted 'Release Date' to 'CREATION_TIMESTAMP' (epoch seconds).")

        # Ensure ITEM_ID is string type for Personalize
        if 'ITEM_ID' in df_selected.columns:
            df_selected['ITEM_ID'] = df_selected['ITEM_ID'].astype(str)

        # Handle other potential data type conversions for Personalize, e.g., boolean values to '0'/'1' or 'True'/'False' strings.
        for col in ['EXPLICIT_CONTENT', 'TAG_PARTY', 'TAG_WORK_STUDY', 'TAG_RELAXATION_MEDITATION',
                     'TAG_EXERCISE', 'TAG_RUNNING', 'TAG_YOGA_STRETCHING', 'TAG_DRIVING',
                     'TAG_SOCIAL_GATHERINGS', 'TAG_MORNING_ROUTINE']:
            if col in df_selected.columns:
                df_selected[col] = df_selected[col].fillna(False).astype(bool).astype(str)
                
        # Fill any remaining NaN values with empty string or appropriate default for Personalize metadata
        df_selected = df_selected.fillna('')

        # --- 7. Save Processed DataFrame ---
        df_selected.to_csv(output_filename, index=False)
        end_time = time.time()
        print(f"Processed data successfully saved to '{output_filename}'.")
        print(f"Total execution time: {end_time - start_time:.2f} seconds.")

    except ImportError:
        print("\nError: Dask or its dependencies are not installed.")
        print("Please install Dask using: `pip install dask[dataframe]`")
        print("After installation, please re-run the script.")
    except KeyError as e:
        print(f"\nError: A required column was not found in the input CSV: {e}.")
        print("Please ensure your CSV file has the expected headers as specified in the script.")
    except Exception as e:
        print(f"\nAn unexpected error occurred during processing: {e}")
        print("Please ensure the CSV file is correctly formatted and accessible.")
        print("Review the traceback for more details or consult Dask/Pandas documentation.")

# --- Call the function to execute the data preparation process ---
# IMPORTANT: Since you indicated the input is already trimmed, we will use
# the output from the previous trimming step as the input here.
# We set 'num_rows_to_keep' to a large number (e.g., 1000000) to ensure all rows
# from this already-trimmed file are processed without re-sampling.
prepare_spotify_for_personalize(input_filename="spotify_100k_trimmed_parallel.csv", output_filename="spotify_personalize_items.csv", num_rows_to_keep=1000000)
