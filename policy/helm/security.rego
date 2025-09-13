package helm.security

# Под запретом запуск privileged контейнеров
deny[msg] {
  input.kind == "Pod"
  c := input.spec.containers[_]
  c.securityContext.privileged == true
  msg := sprintf("Privileged container запрещен: %s", [c.name])
}

# У каждого контейнера должны быть заданы ресурсы
deny[msg] {
  input.kind == "Pod"
  c := input.spec.containers[_]
  not c.resources.limits
  msg := sprintf("Отсутствуют limits у контейнера %s", [c.name])
}
