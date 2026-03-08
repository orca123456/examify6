<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;

use App\Http\Controllers\Api\ClassroomController;
use App\Http\Controllers\Api\AnnouncementController;

use App\Http\Controllers\Api\AssessmentController;
use App\Http\Controllers\Api\StudentAttemptController;
use App\Http\Controllers\Api\BulkUploadController;
use App\Http\Controllers\Api\AnalyticsController;
use App\Http\Controllers\Api\AssessmentTemplateController;

// Public Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/token/refresh', [AuthController::class, 'refresh'])
    ->middleware('throttle:10,1'); // 10 requests per minute

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/user', function (Request $request) {
        return $request->user();
    });

    // Classrooms API
    Route::get('/classrooms', [ClassroomController::class, 'index']);
    Route::post('/classrooms', [ClassroomController::class, 'store'])->middleware('teacher');
    Route::get('/classrooms/{id}', [ClassroomController::class, 'show']);
    Route::patch('/classrooms/{id}', [ClassroomController::class, 'update'])->middleware('teacher');
    Route::patch('/classrooms/{id}/meeting', [ClassroomController::class, 'toggleMeeting'])->middleware('teacher');
    Route::delete('/classrooms/{id}', [ClassroomController::class, 'destroy'])->middleware('teacher');
    Route::post('/join', [ClassroomController::class, 'joinByCode'])->middleware('student');
    Route::get('/classrooms/{id}/students', [ClassroomController::class, 'students']);

    // Announcements API
    Route::get('/classrooms/{id}/announcements', [AnnouncementController::class, 'index']);
    Route::post('/classrooms/{id}/announcements', [AnnouncementController::class, 'store'])->middleware('teacher');
    Route::patch('/announcements/{id}', [AnnouncementController::class, 'update'])->middleware('teacher');
    Route::delete('/announcements/{id}', [AnnouncementController::class, 'destroy'])->middleware('teacher');

    // Assessments API
    Route::get('/classrooms/{id}/assessments', [AssessmentController::class, 'index']);
    Route::post('/classrooms/{id}/assessments', [AssessmentController::class, 'store'])->middleware('teacher');
    Route::get('/assessments/{id}', [AssessmentController::class, 'show']);
    Route::delete('/assessments/{id}', [AssessmentController::class, 'destroy'])->middleware('teacher');
    Route::post('/assessments/{id}/consent', [AssessmentController::class, 'consent'])->middleware('student');
    Route::post('/assessments/{id}/start', [AssessmentController::class, 'start'])->middleware('student');

    // Attempts & Proctoring API
    Route::post('/attempts/{id}/submit', [StudentAttemptController::class, 'submit'])->middleware('student');
    Route::post('/attempts/{id}/proctor-event', [StudentAttemptController::class, 'proctorEvent'])->middleware('student');

    // Results API
    Route::get('/attempts/{id}/result', [\App\Http\Controllers\Api\ResultController::class, 'studentResult'])->middleware('student');
    Route::get('/assessments/{id}/results', [\App\Http\Controllers\Api\ResultController::class, 'teacherResults'])->middleware('teacher');
    Route::get('/assessments/{id}/proctoring-report', [\App\Http\Controllers\Api\ResultController::class, 'proctoringReport'])->middleware('teacher');

    // Teacher Essentials
    Route::post('/students/bulk-upload', [BulkUploadController::class, 'upload'])->middleware('teacher');
    Route::get('/classrooms/{id}/gradebook', [ClassroomController::class, 'gradebook'])->middleware('teacher');
    Route::get('/analytics/exam/{id}', [AnalyticsController::class, 'getExamAnalytics'])->middleware('teacher');
    Route::get('/assessment-templates', [AssessmentTemplateController::class, 'index'])->middleware('teacher');
});
