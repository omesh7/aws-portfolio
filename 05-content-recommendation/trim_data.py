import pandas as pd
import dask.dataframe as dd
import os

def trim_csv_random_parallel(input_filename="spotify_100k_dataset.csv", output_filename="spotify_100k_trimmed_parallel.csv", num_rows_to_keep=100000):
    """
    Reads a CSV file using Dask for potential parallelism and out-of-core processing,
    selects a random sample of N rows (without replacement), and saves the result
    to a new CSV file. This approach is designed for large datasets to improve speed.

    Args:
        input_filename (str): The name of the input CSV file.
        output_filename (str): The name of the output CSV file where the trimmed data will be saved.
        num_rows_to_keep (int): The number of random rows to select from the file.
    """
    print(f"Attempting to trim '{input_filename}' to a random sample of {num_rows_to_keep} rows using Dask for parallelism...")
    print("This approach is optimized for large datasets to reduce execution time and memory usage.")

    # Check if the input file exists
    if not os.path.exists(input_filename):
        print(f"Error: The file '{input_filename}' was not found in the current directory.")
        print("Please make sure the CSV file is in the same directory as this script, or provide the full path.")
        return

    try:
        # Read the CSV file into a Dask DataFrame.
        # Dask reads lazily, in chunks, suitable for files larger than RAM.
        # blocksize can be tuned based on your system's memory and file size.
        # 25MB (25e6 bytes) is a common default chunk size.
        ddf = dd.read_csv(input_filename, low_memory=False, blocksize=25e6)
        print(f"Successfully created Dask DataFrame for '{input_filename}'.")

        # Get the total number of rows. This will trigger a Dask computation
        # to count the rows, which might take some time for very large files,
        # but it's necessary for exact sampling.
        total_rows = len(ddf)
        print(f"Total rows in '{input_filename}': {total_rows}.")

        # Check if the Dask DataFrame has enough rows for sampling
        if total_rows < num_rows_to_keep:
            print(f"Warning: The file only contains {total_rows} rows, which is less than the requested {num_rows_to_keep}.")
            print(f"Saving the entire content ({total_rows} rows) to '{output_filename}'.")
            # Convert the entire Dask DataFrame to a pandas DataFrame and save
            df_trimmed = ddf.compute()
        else:
            # Calculate the fraction of rows to sample
            # Ensure frac is not zero to avoid errors if total_rows is very small or num_rows_to_keep is 0
            frac_to_sample = num_rows_to_keep / total_rows if total_rows > 0 else 0

            if frac_to_sample == 0 and num_rows_to_keep > 0:
                print(f"Warning: Cannot sample {num_rows_to_keep} rows from {total_rows} total rows. Setting frac_to_sample to a very small number for non-zero behavior if num_rows_to_keep > 0.")
                # This case might happen if total_rows is 0, or if num_rows_to_keep is 0
                # If total_rows is 0, df_trimmed will be empty anyway.
                # If num_rows_to_keep is 0, an empty dataframe is expected.
                # If num_rows_to_keep > 0 and total_rows is very large (leading to frac_to_sample ~ 0)
                # Dask's sample might return 0 rows. A small epsilon could be used if strict num_rows_to_keep
                # must be returned, but then it's not truly random and might involve more computation.
                # For this specific case, it implies either source is empty or target is 0,
                # so an empty df_trimmed or full df_trimmed (if total_rows < num_rows_to_keep) is handled.
                pass # The existing logic handles total_rows < num_rows_to_keep, so this path is mostly for clarification.


            # Select a random sample of N rows from the Dask DataFrame using 'frac'.
            # `replace=False` is the default for `sample()` and ensures no repeated rows.
            # `random_state=None` ensures a truly random sample each time the script is run.
            # If you need reproducible results, set `random_state` to an integer (e.g., 42).
            # The `.compute()` call triggers the parallel execution of the sampling and
            # converts the result back into a standard pandas DataFrame.
            df_trimmed = ddf.sample(frac=frac_to_sample, random_state=None).compute()

            # Dask's sample with frac might not return exact 'num_rows_to_keep'
            # especially for small frac or very skewed partitions.
            # To ensure exactly num_rows_to_keep, we can sample again from the pandas DataFrame
            # if the Dask sample returns more than needed, or take all if less.
            if len(df_trimmed) > num_rows_to_keep:
                df_trimmed = df_trimmed.sample(n=num_rows_to_keep, random_state=None)
            print(f"Selected and computed a random sample of {len(df_trimmed)} rows.")


        # Save the trimmed Pandas DataFrame to a new CSV file.
        # `index=False` prevents pandas from writing the DataFrame index as a column in the CSV.
        df_trimmed.to_csv(output_filename, index=False)
        print(f"Trimmed data successfully saved to '{output_filename}'.")

    except ImportError:
        print("Error: Dask or its dependencies are not installed.")
        print("Please install Dask using: `pip install dask[dataframe]`")
        print("After installation, please re-run the script.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        print("Please ensure the CSV file is correctly formatted and accessible.")
        print("If the error persists, check the Dask documentation for troubleshooting.")

# --- Call the function to execute the trimming process ---
# Make sure 'spotify_100k_dataset.csv' is in the same directory as your Python script
# or provide the full path to the file.
trim_csv_random_parallel()
