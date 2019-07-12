require 'json'
require 'httparty'
require 'writeexcel'
require 'open3'
require 'aws-sdk-s3'

imagedir = "/Users/ermadmix/Documents/ruby_scripts/testscripts"

y = YAML.load_file("../config/local_env.yml")

aki = y["ACCESS_KEY_ID"]
sak = y["SECRET_ACCCESS_KEY"]

s3 = Aws::S3::Resource.new(region: 'us-east-1',  access_key_id: aki, secret_access_key: sak)

#bucket = "ycba-iiif-manifests-prod"
#folder = "manifest"
bucket = "ycba-manifest-test2"
folder = "manifest"
puts s3.bucket(bucket).objects(prefix:folder, delimiter: '').collect(&:key)

#to run: ruby list_manifests.rb > output.txt
