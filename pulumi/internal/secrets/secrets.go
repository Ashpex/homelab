package secrets

import (
	"github.com/Ashpex/homelab/pulumi/internal/config"
	"github.com/Ashpex/homelab/pulumi/internal/naming"
	corev1 "github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/core/v1"
	metav1 "github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/meta/v1"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func Create(ctx *pulumi.Context, secrets []config.Secret) error {
	for _, secret := range secrets {
		stringData := pulumi.StringMap{}
		for key, value := range secret.Data {
			stringData[key] = pulumi.String(value)
		}

		namespace := secret.TargetNamespace()
		_, err := corev1.NewSecret(ctx, naming.Resource("secret", namespace+"-"+secret.Name), &corev1.SecretArgs{
			Metadata: &metav1.ObjectMetaArgs{
				Name:      pulumi.String(secret.Name),
				Namespace: pulumi.String(namespace),
				Labels: pulumi.StringMap{
					"app.kubernetes.io/managed-by": pulumi.String("pulumi"),
					"app.kubernetes.io/part-of":    pulumi.String("homelab"),
				},
			},
			StringData: stringData,
			Type:       pulumi.String("Opaque"),
		})
		if err != nil {
			return err
		}
	}

	ctx.Export("secretCount", pulumi.Int(len(secrets)))
	return nil
}
