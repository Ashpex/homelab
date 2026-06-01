package naming

import (
	"fmt"
	"strings"
)

var replacer = strings.NewReplacer(".", "-", "_", "-", "*", "wildcard")

func Resource(prefix, name string) string {
	return fmt.Sprintf("%s-%s", prefix, replacer.Replace(name))
}
