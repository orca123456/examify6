<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Classroom;
use Illuminate\Support\Str;

class ClassroomController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'teacher') {
            $classrooms = $request->user()->classrooms()->withCount('students')->get();
        } else {
            $classrooms = $request->user()->enrolledClassrooms()->with('teacher:id,name,email,teacher_id')->get();
        }

        return response()->json($classrooms, 200);
    }

    public function show(Request $request, $id)
    {
        $classroom = Classroom::with('teacher:id,name,email,role')->findOrFail($id);
        $user = $request->user();

        // Authorization: Teacher of the class or Enrolled student
        $isTeacher = $classroom->teacher_id === $user->id;
        $isStudent = $classroom->students()->where('users.id', $user->id)->exists();

        if (!$isTeacher && !$isStudent) {
            abort(403);
        }

        return response()->json($classroom, 200);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
        ]);

        $joinCode = strtoupper(Str::random(6));
        while (Classroom::where('join_code', $joinCode)->exists()) {
            $joinCode = strtoupper(Str::random(6));
        }

        $classroom = $request->user()->classrooms()->create([
            'name' => $validated['name'],
            'description' => $validated['description'],
            'join_code' => $joinCode,
        ]);

        return response()->json(['classroom' => $classroom], 201);
    }

    public function join(Request $request, $id)
    {
        $validated = $request->validate([
            'join_code' => 'required|string|size:6',
        ]);

        $classroom = Classroom::findOrFail($id);

        if ($classroom->join_code !== strtoupper($validated['join_code'])) {
            return response()->json(['message' => 'Invalid join code'], 400);
        }

        if ($classroom->students()->where('users.id', $request->user()->id)->exists()) {
            return response()->json(['message' => 'Already joined'], 409);
        }

        $classroom->students()->attach($request->user()->id);

        return response()->json(['message' => 'Joined successfully'], 200);
    }

    public function joinByCode(Request $request)
    {
        $validated = $request->validate([
            'join_code' => 'required|string|size:6',
        ]);

        $classroom = Classroom::where('join_code', strtoupper($validated['join_code']))->first();

        if (!$classroom) {
            return response()->json(['message' => 'Invalid join code'], 404);
        }

        if ($classroom->students()->where('users.id', $request->user()->id)->exists()) {
            return response()->json(['message' => 'Already joined'], 409);
        }

        $classroom->students()->attach($request->user()->id);

        $classroom->load('teacher:id,name,email,teacher_id');

        return response()->json(['message' => 'Joined successfully', 'classroom' => $classroom], 200);
    }

    public function students(Request $request, $id)
    {
        $classroom = Classroom::findOrFail($id);
        $user = $request->user();

        // Authorization: Teacher of the class or Enrolled student
        $isTeacher = $classroom->teacher_id === $user->id;
        $isStudent = $classroom->students()->where('users.id', $user->id)->exists();

        if (!$isTeacher && !$isStudent) {
            abort(403);
        }

        return response()->json($classroom->students()->select('users.id', 'users.name', 'users.email', 'users.role', 'users.student_id', 'users.section')->get(), 200);
    }

    public function gradebook($id)
    {
        $classroom = Classroom::findOrFail($id);
        $students = $classroom->students()->get();
        $calcService = new \App\Services\GradeCalculationService();

        $gradebook = $students->map(function ($student) use ($classroom, $calcService) {
            $grade = $calcService->calculateWeightedAverage($classroom, $student);

            $scores = [];
            foreach ($classroom->assessments as $assessment) {
                $attempt = $student->attempts()->where('assessment_id', $assessment->id)->where('status', 'submitted')->first();
                $scores[$assessment->title] = $attempt ? (double) $attempt->score : 0.0;
            }

            return [
                'id' => $student->id,
                'student_id' => $student->student_id ?? 'N/A',
                'name' => $student->name,
                'email' => $student->email,
                'section' => $student->section ?? 'N/A',
                'scores' => $scores,
                'calculated_grade' => round((double) $grade, 1),
            ];
        });

        return response()->json($gradebook);
    }

    public function update(Request $request, $id)
    {
        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
        ]);

        $classroom->update($validated);

        return response()->json($classroom, 200);
    }

    public function destroy(Request $request, $id)
    {
        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();
        $classroom->delete();

        return response()->json(['message' => 'Classroom deleted'], 200);
    }

    public function toggleMeeting(Request $request, $id)
    {
        $classroom = Classroom::where('id', $id)->where('teacher_id', $request->user()->id)->firstOrFail();

        $validated = $request->validate([
            'is_meeting_active' => 'required|boolean',
        ]);

        $classroom->update(['is_meeting_active' => $validated['is_meeting_active']]);

        return response()->json([
            'message' => 'Meeting state updated',
            'is_meeting_active' => $classroom->is_meeting_active
        ], 200);
    }
}
