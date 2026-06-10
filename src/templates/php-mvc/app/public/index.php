<?php

spl_autoload_register(function (string $class): void {
    require __DIR__ . '/../src/controllers/' . $class . '.php';
});

$controller = new HomeController();
$controller->index();
