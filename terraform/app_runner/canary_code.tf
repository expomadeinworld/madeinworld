# Pack and upload canary code

data "archive_file" "auth_ready_zip" {
  type        = "zip"
  output_path = "${path.module}/auth_ready.zip"
  source {
    content  = <<-EOT
      const synthetics = require('Synthetics');
      const api = async function () {
        const url = process.env.TARGET_URL;
        const request = require('request-promise-native');
        const resp = await request({ uri: url, resolveWithFullResponse: true, simple: false });
        if (resp.statusCode !== 200) {
          throw new Error('Non-200 status: ' + resp.statusCode);
        }
      };
      exports.handler = async () => await api();
    EOT
    filename = "index.js"
  }
}

resource "aws_s3_object" "canary_code" {
  bucket = data.aws_s3_bucket.synthetics_artifacts.bucket
  key    = "canaries/auth_ready.zip"
  source = data.archive_file.auth_ready_zip.output_path
  etag   = filemd5(data.archive_file.auth_ready_zip.output_path)
}

