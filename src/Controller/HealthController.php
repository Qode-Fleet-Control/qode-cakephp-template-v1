<?php
declare(strict_types=1);

namespace App\Controller;

use Cake\Http\Response;

/**
 * The fleet's health check (fleet.conf HEALTH_PATH), routed as /health in config/routes.php.
 */
class HealthController extends AppController
{
    public function index(): Response
    {
        return $this->response
            ->withType('application/json')
            ->withStringBody((string)json_encode(['status' => 'ok']));
    }
}
