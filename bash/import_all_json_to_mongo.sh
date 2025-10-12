#!/bin/bash

# config
MONGO_URI="mongodb://localhost:27017"
DATABASE="insight_mongo"

# corent dir
DIRECTORY="$(pwd)"

echo "start import from JSON files in : $DIRECTORY"
echo "target DB : $DATABASE"
echo "-----------------------------------------"

for file in "$DIRECTORY"/*.json; do

    [ -e "$file" ] || { echo " JSON file not fond."; exit 0; }


    collection=$(basename "$file" .json)

    echo "importing file: $file"
    echo "into collection: $collection"

    mongoimport --uri="$MONGO_URI/$DATABASE" --collection="$collection" --file="$file" --jsonArray --drop

    if [ $? -eq 0 ]; then
        echo "import succesful: $collection"
    else
        echo "import fail: $collection"
    fi

    echo "-----------------------------------------"
done

echo "import don."
