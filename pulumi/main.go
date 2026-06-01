package main

import (
	"github.com/Ashpex/homelab/pulumi/internal/stack"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(stack.Run)
}
