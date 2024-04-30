import requests
from typing import Union
from fastapi import FastAPI
from pydantic import BaseModel
import random

app = FastAPI(debug=True)

url = 'https://poetrydb.org/author' # define the api url

all_names_response = requests.get(url) # make a GET request API call

all_names_json = all_names_response.json() # return json value of the GET request response

all_names_list = all_names_json["authors"] # retrieve value of the authors list

class Letter(BaseModel):
    letter: str

@app.get("/health")
def healthy():
    return "healthy"

@app.post("/names")
def get_poet_name(letter: Letter): 
    matching_names = [] # an empty list to append all matching names
    for word in all_names_list: # loop through all the provided poet names from the poetry api
        if word.startswith(letter.letter.upper()): # check if any name in poet name starts with provided letter
            matching_names.append(word) # append all matching names in the empty list

    if matching_names == []:
        return {
            "message": "No Poet found"
        }
    else:
        random_poet_name = random.choice(matching_names)
        return {
            "poet_name" : random_poet_name # return a random poet name that starts with the letter provided
        }

    