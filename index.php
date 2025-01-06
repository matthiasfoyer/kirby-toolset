<?php

include __DIR__ . '/kirby/bootstrap.php';

$kirby = new Kirby([
    'roots' => [
        'content' => dirname(__DIR__) . '/${project_name}-content'
    ]
]);

echo $kirby->render();