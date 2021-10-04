#!/bin/env python3

import sys
import os
import shlex
import subprocess
import json
import configparser
import argparse


def main(args):

    stream = subprocess.check_output(
        shlex.split(f"aws iam list-mfa-devices --profile {args.profile} --output json")
    )

    if args.mfa_device:
        mfa_device = args.mfa_device
    else:
        mfa_device = json.loads(stream)["MFADevices"][0]["SerialNumber"]

    try:
        stream = subprocess.check_output(
            [
                "aws",
                "sts",
                "get-session-token",
                "--serial-number",
                mfa_device,
                "--token-code",
                args.token,
                "--profile",
                args.profile,
                "--output",
                "json",
                "--duration-seconds",
                "129600",
            ]
        )

        info = json.loads(stream)
        path = os.path.join(os.path.expanduser("~"), ".aws/credentials")

        config = configparser.ConfigParser()
        config.read(path)
        config.update(
            {
                "default": dict(
                    output="json",
                    aws_access_key_id=info["Credentials"]["AccessKeyId"],
                    aws_secret_access_key=info["Credentials"]["SecretAccessKey"],
                    aws_session_token=info["Credentials"]["SessionToken"],
                )
            }
        )

        with open(path, "w") as fd:
            config.write(fd)
    except subprocess.CalledProcessError as e:
        print(e.output)
        return -1


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("token", help="the mfa token from your device")
    parser.add_argument("--profile", help="the profile to use")
    parser.add_argument(
        "--mfa-device", default="", type=str, help="the mfa device arn to use"
    )

    main(parser.parse_args(sys.argv[1:]))
