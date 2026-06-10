<?php

class HomeController
{
    public function index(): void
    {
        $data = ['message' => 'Hello PHP MVC!! UWUlO50F1D'];
        require __DIR__ . '/../views/home.php';
    }
}
