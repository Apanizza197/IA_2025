
locals {
  layer_name  = "google-genai"
  build_dir   = "${path.module}/build"              # cleaned / recreated each apply
  python_dir  = "${local.build_dir}/python"
  layer_zip   = "${local.build_dir}/${local.layer_name}.zip"
}

resource "null_resource" "pip_install" {
  triggers = {
    # Re-run if any dependency line changes
    deps_hash = filesha256("${path.module}/lambda_scripts/requirements.txt")
  }

  provisioner "local-exec" {
    command = <<EOT
set -e
rm -rf ${local.build_dir}
mkdir -p ${local.python_dir}
pip install --upgrade pip >/dev/null
pip install -r ${path.module}/lambda_scripts/requirements.txt -t ${local.python_dir} >/dev/null
EOT
  }
}

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = local.build_dir          # contains python/
  output_path = local.layer_zip
  depends_on  = [null_resource.pip_install]
}

resource "aws_lambda_layer_version" "genai" {
  layer_name          = local.layer_name
  filename            = data.archive_file.layer_zip.output_path
  compatible_runtimes = ["python3.12", "python3.11", "python3.10"]
  description         = "google-generativeai SDK and its dependencies"

  # Forces a new layer version when ZIP content changes
  source_code_hash = data.archive_file.layer_zip.output_base64sha256

  lifecycle {
    create_before_destroy = true   # avoids downtime for functions that use the layer
  }
}
