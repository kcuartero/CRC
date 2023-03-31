import os
from flask import Flask, request
from flask_cors import CORS
from google.cloud import datastore  

#initialize flask app
app = Flask(__name__)
CORS(app)

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "kcuartero-crc-tf-bb80eed0b9fa.json"

#initialize a datastore client and entity
client = datastore.Client(project="kcuartero-crc-tf")
entityRef = client.key("visitorCount", 5634161670881280)

# add +1 to visitorCount
@app.route("/count", methods=['GET', 'POST'])
def saveCount():
    if request.method == "GET" or request.method == "POST":
        key = client.get(entityRef)
        key['count'] += 1
        client.put(key)
        count = dict(key)
        return count
    else: 
        return "Method not allow", 405

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))