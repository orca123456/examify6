<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Classroom extends Model
{
    use HasFactory;

    protected $fillable = [
        'teacher_id',
        'name',
        'description',
        'join_code',
        'is_meeting_active',
    ];

    public function teacher()
    {
        return $this->belongsTo(User::class, 'teacher_id');
    }

    public function students()
    {
        return $this->belongsToMany(User::class, 'classroom_students', 'classroom_id', 'student_id');
    }

    public function assessments()
    {
        return $this->hasMany(Assessment::class);
    }

    public function announcements()
    {
        return $this->hasMany(Announcement::class);
    }
}
