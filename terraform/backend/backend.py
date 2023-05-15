import os
import json
import boto3
from pymongo import MongoClient
from bson.json_util import dumps
from bson import ObjectId

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
client = MongoClient(f'mongodb://{USERNAME}:{PASSWORD}@{HOST}:{PORT}/?ssl=true&retryWrites=false')
db = client[DB_NAME]

def handler(event, context):
    operation = event['httpMethod']

    path_parameters = event.get('pathParameters')
    if path_parameters:
        proxy = path_parameters.get('proxy', '')
        proxy_parts = proxy.split('/')
        if len(proxy_parts) > 1:
            event['id'] = proxy_parts[1]

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
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Credentials': 'true'
            },
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
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Credentials': 'true'
            },
            'body': dumps(result)
        }
    else:
        # Otherwise, retrieve all posts
        result = db.posts.find()

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Credentials': 'true'
            },
            'body': dumps(list(result))
        }


def handle_post(event):
    body = json.loads(event['body'])
    result = db.posts.insert_one(body)

    return {
        'statusCode': 201,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': 'true'
        },
        'body': dumps({'_id': result.inserted_id})
    }

def handle_put(event):
    post_id = event['id']
    body = json.loads(event['body'])

    result = db.posts.update_one({'_id': ObjectId(post_id)}, {'$set': body})

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': 'true'
        },
        'body': dumps({'matched_count': result.matched_count, 'modified_count': result.modified_count})
    }

def handle_delete(event):
    path_parameters = event.get('pathParameters')
    if path_parameters:
        proxy = path_parameters.get('proxy', '')
        proxy_parts = proxy.split('/')
        if len(proxy_parts) > 1:
            post_id = proxy_parts[1]
        else:
            post_id = path_parameters.get('id', None)
    else:
        post_id = None

    if post_id is None:
        return {
            'statusCode': 400,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Credentials': 'true'
            },
            'body': 'No ID provided'
        }

    result = db.posts.delete_one({'_id': ObjectId(post_id)})

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': 'true'
        },
        'body': dumps({'deleted_count': result.deleted_count})
    }
