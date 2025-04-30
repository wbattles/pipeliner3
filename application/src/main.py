from flask import Flask, jsonify, request
import boto3
import logging
import json

logger = logging.getLogger(__name__)

class SecretWrapper:
    def __init__(self, secretsmanager_client):
        self.client = secretsmanager_client

    def get_secret(self, secret_name):
        try:
            get_secret_value_response = self.client.get_secret_value(
                SecretId=secret_name
            )
            return get_secret_value_response["SecretString"]
        except self.client.exceptions.ResourceNotFoundException:
            msg = f"The requested secret {secret_name} was not found."
            return msg
        except Exception as e:
            logger.error(f"An unknown error occurred: {str(e)}.")
            raise

def get_secret(secret_name, region_name):
    session = boto3.session.Session()
    client = session.client(
        service_name="secretsmanager",
        region_name=region_name
    )

    secret = SecretWrapper(client)
    return secret.get_secret(secret_name)

class DynamoDBWrapper:
    def __init__(self, table):
        self.table = table

    def get_item(self, key):
        try:
            response = self.table.get_item(Key=key)
            return response.get('Item', None)
        except Exception as e:
            logger.error(f"An error occurred while getting item: {str(e)}.")
            raise

    def put_item(self, name, color, type):
        try:
            response = self.table.put_item(
                Item={
                    'name': name,
                    'color': color,
                    'type': type
                }
            )
            return response
        except Exception as e:
            logger.error(f"An error occurred while adding movie: {str(e)}.")
            raise

def create_app():
    app = Flask(__name__)
    
    region_name = "us-east-1"
    table_name = "test-table"
    dynamodb_resource = boto3.resource('dynamodb', region_name=region_name)
    table = dynamodb_resource.Table(table_name)
    db_wrapper = DynamoDBWrapper(table)

    test_secret = get_secret("TestSecret", region_name)
    API_KEY = json.loads(test_secret)["API_KEY"]

    @app.before_request
    def verify_api_key():
        api_key = request.headers.get('x-api-key')
        if api_key != API_KEY:
            logger.warning("Invalid API key provided.")
            return jsonify({"error": "Invalid API key"}), 403

    @app.route('/')
    def home():
        return "Hello darlin"
    
    @app.route('/get_item/<item_id>', methods=['GET'])
    def get_item(item_id):
        try:
            item = db_wrapper.get_item({'itemID': item_id})
            if item:
                return item
            else:
                return {"error": "Item not found"}, 404
        except Exception as e:
            logger.error(f"An error occurred while retrieving item: {str(e)}.")
            return {"error": str(e)}, 500

    @app.route('/add_item', methods=['POST'])
    def add_item():
        try:
            item_data = request.get_json()
            response = table.put_item(Item=item_data)
            return jsonify({"message": "Item added", "response": response}), 201
        except Exception as e:
            logger.error(f"Error putting item: {e}")
            return jsonify({"error": str(e)}), 500

    return app