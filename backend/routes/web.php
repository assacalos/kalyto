<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    return response()->json([
        'name'    => 'EasyConnect API',
        'version' => '1.0',
        'status'  => 'ok',
        'docs'    => url('/api'),
    ], 200, ['Content-Type' => 'application/json']);
});

