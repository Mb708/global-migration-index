using Countries, CSV, DataFrames

# Function to get ISO 3-digit code from country name
function get_country_code(country_name::String)
    # Handle empty or missing values
    if ismissing(country_name) || isempty(strip(country_name))
        return missing
    end
    
    country_name = strip(country_name)  # Remove whitespace
    
    try
        # Try exact match first
        country = Countries.country(country_name)
        return country.alpha3
    catch
        # If exact match fails, try fuzzy matching
        all_countries = Countries.all()
        
        # Common name variations and mappings
        name_variations = Dict(
            "USA" => "United States",
            "US" => "United States", 
            "UK" => "United Kingdom",
            "Britain" => "United Kingdom",
            "Russia" => "Russian Federation",
            "South Korea" => "Korea, Republic of",
            "North Korea" => "Korea, Democratic People's Republic of",
            "Iran" => "Iran, Islamic Republic of",
            "Venezuela" => "Venezuela, Bolivarian Republic of",
            "Vietnam" => "Viet Nam",
            "Czech Republic" => "Czechia",
            "Macedonia" => "North Macedonia",
            "Congo" => "Congo, Democratic Republic of the",
            "Tanzania" => "Tanzania, United Republic of",
            "Syria" => "Syrian Arab Republic",
            "Bolivia" => "Bolivia, Plurinational State of"
        )
        
        # Check if it's a known variation
        if haskey(name_variations, country_name)
            try
                country = Countries.country(name_variations[country_name])
                return country.alpha3
            catch
            end
        end
        
        # Try case-insensitive exact match
        for country in all_countries
            if lowercase(country.name) == lowercase(country_name)
                return country.alpha3
            end
        end
        
        # Try partial matching
        for country in all_countries
            if occursin(lowercase(country_name), lowercase(country.name)) ||
               occursin(lowercase(country.name), lowercase(country_name))
                return country.alpha3
            end
        end
        
        # Return missing if no match found
        return missing
    end
end

# Let's examine the raw structure of the CSV file first
println("=== Examining raw CSV structure ===")

# Read first few lines as strings to see the actual structure
lines = readlines("WPS-Index-data-final.csv")
println("First 10 lines of the raw CSV:")
for (i, line) in enumerate(lines[1:min(10, length(lines))])
    println("Line $i: $line")
end

println("\n=== Attempting to read with different parameters ===")

# Try reading with different skip rows - often statistical tables have headers in row 2 or 3
for skip_rows in 0:5
    try
        df_test = CSV.read("WPS-Index-data-final.csv", DataFrame, header=skip_rows+1, skipto=skip_rows+2)
        println("\nWith header at row $(skip_rows+1):")
        println("Columns: ", names(df_test))
        if nrow(df_test) > 0
            println("First row: ", first(df_test, 1))
        end
    catch e
        println("Skip $skip_rows failed: $e")
    end
end

# Once we find the correct structure, we'll use this to read the data properly
# You'll need to adjust these parameters based on the output above:

# Example: if the real headers are in row 3, use:
# df = CSV.read("", DataFrame, header=3, skipto=4)

# For now, let's try a common case - headers in row 2:
try
    df = CSV.read("WPS-Index-data-final.csv", DataFrame, header=2, skipto=3)
    println("\n=== Successfully read with header in row 2 ===")
    println("Columns: ", names(df))
    println("First few rows:")
    println(first(df, 3))
    
    # Now find the country column
    country_col = nothing
    
    # Look for country-related column names
    for col_name in names(df)
        col_str = string(col_name)
        if occursin(r"country|nation|state"i, col_str)
            country_col = col_name
            println("Found likely country column: $country_col")
            break
        end
    end
    
    # Set the country column to Column2 as specified
    country_col = Symbol("Country")
    println("Using Column2 as the country column")
    # Add the ISO 3-digit code column
    df[!, :iso3_code] = [get_country_code(string(country)) for country in df[!, country_col]]
    
    # Check for any missing codes
    missing_codes = df[ismissing.(df.iso3_code), :]
    if nrow(missing_codes) > 0
        println("Countries without matches:")
        println(missing_codes[!, country_col])
    end
    
    # Save the updated CSV
    CSV.write("your_file_with_codes.csv", df)
    println("Updated CSV saved as 'your_file_with_codes.csv'")
    
    # Display the first few rows
    println("\nFirst 5 rows of updated data:")
    println(first(df, 5))
    
    # Show summary
    println("\nSummary:")
    println("Total countries: ", nrow(df))
    println("Countries with ISO codes: ", count(!ismissing, df.iso3_code))
    println("Countries without ISO codes: ", count(ismissing, df.iso3_code))
    
catch e
    println("Error reading with header in row 2: $e")
    println("Please check the raw structure above and manually specify the correct header row.")
end