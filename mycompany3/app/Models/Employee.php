<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Employee extends Model
{
    use HasFactory;

    // Allowed values for contract_id
    const CONTRACT_ORIGINAL = 'original';
    const CONTRACT_RENTAL = 'rental';
    const CONTRACT_EXTERNAL = 'external';

    protected $fillable = [
        'sn',
        'id_name',
        'iqamah_number',
        'id_number',
        'nationality',
        'passport_number',
        'gender',
        'job_title',
        'housing_id',
        'housing_name',
        'building_id',
        'floor_id',
        'room_id',
        'project_id',
        'project_name',
        'project_code',
        'contract_id',
        'phone_number',
        'email',
        'joining_date',
        'left_date',
        'cases_issues',
        'attachment',
        'note',
    ];


    // Employee attachments
    public function attachments()
    {
        return $this->hasMany(EmployeeAttachment::class);
    }

    // Employee cases or issues
    public function cases()
    {
        return $this->hasMany(EmployeeCase::class);
    }

    // Employee relation with room
    public function room()
    {
        return $this->belongsTo(Room::class, 'room_id');
    }

    // Employee relation with housing
    public function housing()
    {
        return $this->belongsTo(Housing::class, 'housing_id');
    }

    // Employee relation with project
    public function project()
    {
        return $this->belongsTo(Project::class, 'project_id');
    }

    // Employee relation with building
    public function building()
    {
        return $this->belongsTo(Building::class, 'building_id');
    }

    /**
     * Get Arabic contract name
     */
    public function getContractNameAttribute()
    {
        $contractNames = [
            'original' => 'أصلي',
            'rental' => 'إيجار',
            'external' => 'خارجي'
        ];
        
        return $contractNames[$this->contract_id] ?? $this->contract_id;
    }

    /**
     * Scope for active employees (not left)
     */
    public function scopeActive($query)
    {
        return $query->whereNull('left_date');
    }

    /**
     * Scope for search
     */
    public function scopeSearch($query, $searchTerm)
    {
        if (empty($searchTerm)) {
            return $query;
        }

        return $query->where(function ($q) use ($searchTerm) {
            $q->where('id_name', 'like', "%{$searchTerm}%")
              ->orWhere('id_number', 'like', "%{$searchTerm}%")
              ->orWhere('iqamah_number', 'like', "%{$searchTerm}%")
              ->orWhere('job_title', 'like', "%{$searchTerm}%")
              ->orWhere('phone_number', 'like', "%{$searchTerm}%")
              ->orWhere('email', 'like', "%{$searchTerm}%");
        });
    }

    /**
     * Scope for project filter with join
     */
    public function scopeByProject($query, $projectId)
    {
        if (empty($projectId)) {
            return $query;
        }

        return $query->where('project_id', $projectId);
    }

    /**
     * Scope for building filter with join
     */
    public function scopeByBuilding($query, $buildingId)
    {
        if (empty($buildingId)) {
            return $query;
        }

        return $query->where('building_id', $buildingId);
    }

    /**
     * Scope for housing filter with join
     */
    public function scopeByHousing($query, $housingId)
    {
        if (empty($housingId)) {
            return $query;
        }

        return $query->where('housing_id', $housingId);
    }

    /**
     * Scope for contract type filter
     */
    public function scopeByContractType($query, $contractType)
    {
        if (empty($contractType)) {
            return $query;
        }

        return $query->where('contract_id', $contractType);
    }

    /**
     * Scope to eager load all necessary relations
     */
    public function scopeWithAllRelations($query)
    {
        return $query->with(['project', 'building', 'housing']);
    }

    /**
     * Format employee data for API response with relations
     */
    public function formatForApi()
    {
        // Load relations if not already loaded
        if (!$this->relationLoaded('project')) {
            $this->load('project');
        }
        if (!$this->relationLoaded('building')) {
            $this->load('building');
        }
        if (!$this->relationLoaded('housing')) {
            $this->load('housing');
        }
        
        return [
            'id' => $this->id,
            'sn' => $this->sn,
            'id_name' => $this->id_name,
            'iqamah_number' => $this->iqamah_number,
            'id_number' => $this->id_number,
            'nationality' => $this->nationality,
            'job_title' => $this->job_title,
            'housing_id' => $this->housing_id,
            'housing_name' => $this->housing?->name ?? $this->housing_name,
            'building_id' => $this->building_id,
            'building_name' => $this->building?->name ?? $this->building_id,
            'project_id' => $this->project_id,
            'project_name' => $this->project?->name ?? $this->project_name,
            'contract_id' => $this->getContractNameAttribute(),
            'contract_type' => $this->contract_id,
            'phone_number' => $this->phone_number,
            'email' => $this->email,
            'joining_date' => $this->joining_date ? $this->joining_date->format('Y-m-d') : null,
            'created_at' => $this->created_at->format('Y-m-d H:i:s'),
        ];
    }

    /**
     * Calculate contract statistics from a query
     */
    public function calculateContractStatistics($query)
    {
        $total = $query->count();
        
        // Count by contract type
        $originalCount = (clone $query)->where('contract_id', self::CONTRACT_ORIGINAL)->count();
        $rentalCount = (clone $query)->where('contract_id', self::CONTRACT_RENTAL)->count();
        $externalCount = (clone $query)->where('contract_id', self::CONTRACT_EXTERNAL)->count();

        return [
            'total' => $total,
            'original' => $originalCount,
            'rental' => $rentalCount,
            'external' => $externalCount
        ];
    }

    /**
     * Get filter options with relations (جعلها non-static)
     */
    public function getFilterOptions()
    {
        return [
            'projects' => Project::select('id', 'name')
                ->get()
                ->map(function ($project) {
                    return [
                        'id' => $project->id,
                        'name' => $project->name,
                        'value' => $project->id,
                        'display_name' => $project->name
                    ];
                })
                ->toArray(),

            'buildings' => Building::select('id', 'name')
                ->get()
                ->map(function ($building) {
                    return [
                        'id' => $building->id,
                        'name' => $building->name,
                        'value' => $building->id,
                        'display_name' => $building->name
                    ];
                })
                ->toArray(),

            'housings' => Housing::select('id', 'name')
                ->get()
                ->map(function ($housing) {
                    return [
                        'id' => $housing->id,
                        'name' => $housing->name,
                        'value' => $housing->id,
                        'display_name' => $housing->name
                    ];
                })
                ->toArray(),

            'contract_types' => [
                [
                    'id' => 1,
                    'name' => 'original',
                    'value' => 'original',
                    'display_name' => 'أصلي'
                ],
                [
                    'id' => 2,
                    'name' => 'rental',
                    'value' => 'rental',
                    'display_name' => 'إيجار'
                ],
                [
                    'id' => 3,
                    'name' => 'external',
                    'value' => 'external',
                    'display_name' => 'خارجي'
                ]
            ]
        ];
    }
}