import os
import json
import boto3
from pymongo import MongoClient
from bson.json_util import dumps

# DocumentDB configuration
HOST = os.environ['DOCDB_HOST']
PORT = 27017
DB_NAME = os.environ.get('DB_NAME', 'blog')

# Create a Secrets Manager client
session = boto3.session.Session()
client = session.client(service_name='secretsmanager', region_name=os.environ["AWS_REGION"])

def get_secret():
    try:
        get_secret_value_response = client.get_secret_value(SecretId=os.environ['SECRET_NAME'])
    except Exception as e:
        raise Exception("Error while retrieving the secret: " + str(e))
    else:
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return json.loads(secret)
        else:
            raise Exception("Could not retrieve the secret string")

secret = get_secret()
USERNAME = secret['username']
PASSWORD = secret['password']

# Create a MongoDB client
client = MongoClient(f'mongodb://{USERNAME}:{PASSWORD}@{HOST}:{PORT}/?ssl=true')
db = client[DB_NAME]

def handler(event, context):
    operation = event['httpMethod']

    if operation == 'GET':
        return handle_get(event)
    elif operation == 'POST':
        return handle_post(event)
    elif operation == 'PUT':
        return handle_put(event)
    elif operation == 'DELETE':
        return handle_delete(event)
    else:
        return {
            'statusCode': 400,
            'body': 'Invalid operation'
        }

def handle_get(event):
    # If an ID is provided, retrieve just that post
    path_parameters = event.get('pathParameters')
    if path_parameters and 'id' in path_parameters:
        post_id = path_parameters['id']
        result = db.posts.find_one({'_id': post_id})

        return {
            'statusCode': 200,
            'body': dumps(result)
        }
    else:
        # Otherwise, retrieve all posts
        result = db.posts.find()

        return {
            'statusCode': 200,
            'body': dumps(list(result))
        }

def handle_post(event):
    body = json.loads(event['body'])
    result = db.posts.insert_one(body)

    return {
        'statusCode': 201,
        'body': dumps({'_id': result.inserted_id})
    }

def handle_put(event):
    post_id = event['pathParameters']['id']
    body = json.loads(event['body'])

    result = db.posts.update_one({'_id': post_id}, {'$set': body})

    return {
        'statusCode': 200,
        'body': dumps({'matched_count': result.matched_count, 'modified_count': result.modified_count})
    }

def handle_delete(event):
    post_id = event['pathParameters']['id']

    result = db.posts.delete_one({'_id': post_id})

    return {
        'statusCode': 200,
        'body': dumps({'deleted_count': result.deleted_count})
    }
