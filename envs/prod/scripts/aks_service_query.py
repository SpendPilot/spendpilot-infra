import json
import subprocess
import sys


def main() -> int:
    query = json.load(sys.stdin)

    cmd = [
        "az",
        "aks",
        "command",
        "invoke",
        "--resource-group",
        query["resource_group_name"],
        "--name",
        query["cluster_name"],
        "--command",
        f"kubectl get svc {query['service_name']} -n {query['namespace']} -o json",
        "--output",
        "json",
    ]

    result = subprocess.run(cmd, check=True, capture_output=True, text=True)
    invoke_payload = json.loads(result.stdout)
    service_payload = json.loads(invoke_payload["logs"])

    ingress = (
        service_payload.get("status", {})
        .get("loadBalancer", {})
        .get("ingress", [{}])
    )
    first = ingress[0] if ingress else {}

    print(json.dumps({
        "ip": first.get("ip", ""),
        "hostname": first.get("hostname", ""),
    }))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
