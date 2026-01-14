<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PaymentReminder;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class PaymentReminderController extends Controller
{
    /**
     * Display all reminders
     */
    public function index()
    {
        $reminders = PaymentReminder::with(['housing', 'building'])->latest()->get();
        
        return response()->json($reminders);
    }

    /**
     * Create new reminder with file upload - FIXED VERSION
     */
    public function store(Request $request)
    {
        // ✅ تحويل payment_status من "1"/"0" إلى boolean
        $requestData = $request->all();
        
        if (isset($requestData['payment_status'])) {
            if ($requestData['payment_status'] === '1' || $requestData['payment_status'] === 'true') {
                $requestData['payment_status'] = true;
            } elseif ($requestData['payment_status'] === '0' || $requestData['payment_status'] === 'false') {
                $requestData['payment_status'] = false;
            }
        }

        $validator = Validator::make($requestData, [
            'housing_id'    => 'required|exists:housings,id',
            'building_id'   => 'nullable|exists:buildings,id',
            'payment_type'  => 'required|in:electricity,water,other',
            'due_date'      => 'required|date',
            'amount'        => 'required|numeric|min:0',
            'payment_status'=> 'boolean',
            'notes'         => 'nullable|string',
            'attachments'   => 'nullable|array',
            'attachments.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,xls,xlsx|max:5120', // 5MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Invalid data',
                'errors' => $validator->errors()
            ], 422);
        }

        $validated = $validator->validated();
        
        // Process attachments
        $attachments = [];
        if ($request->hasFile('attachments')) {
            foreach ($request->file('attachments') as $file) {
                if ($file->isValid()) {
                    $fileName = 'attachment_' . time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                    $file->storeAs('public/attachments', $fileName);
                    $attachments[] = $fileName;
                }
            }
        }
        
        $validated['attachments'] = !empty($attachments) ? $attachments : null;

        // ✅ إذا كان payment_status = true، ضع تاريخ paid_at
        if (isset($validated['payment_status']) && $validated['payment_status'] === true) {
            $validated['paid_at'] = now();
        }

        $reminder = PaymentReminder::create($validated);

        // ✅ إرجاع البيانات مع الأنواع الصحيحة لـ Flutter
        return response()->json([
            'message' => 'Payment reminder created successfully',
            'data'    => [
                'id' => (int) $reminder->id,
                'housing_id' => (int) $reminder->housing_id,
                'building_id' => $reminder->building_id ? (int) $reminder->building_id : null,
                'payment_type' => $reminder->payment_type,
                'due_date' => $reminder->due_date->format('Y-m-d'),
                'amount' => (float) $reminder->amount,
                'payment_status' => (bool) $reminder->payment_status,
                'notes' => $reminder->notes,
                'attachments' => $reminder->attachments,
                'paid_at' => $reminder->paid_at ? $reminder->paid_at->toIso8601String() : null, // ✅ إضافة paid_at
                'created_at' => $reminder->created_at->toIso8601String(),
                'updated_at' => $reminder->updated_at->toIso8601String(),
            ]
        ], 201);
    }

    /**
     * Display specific reminder
     */
    public function show($id)
    {
        $reminder = PaymentReminder::with(['housing', 'building'])->findOrFail($id);
        
        // ✅ إرجاع البيانات مع الأنواع الصحيحة
        return response()->json([
            'id' => (int) $reminder->id,
            'housing_id' => (int) $reminder->housing_id,
            'building_id' => $reminder->building_id ? (int) $reminder->building_id : null,
            'payment_type' => $reminder->payment_type,
            'due_date' => $reminder->due_date->format('Y-m-d'),
            'amount' => (float) $reminder->amount,
            'payment_status' => (bool) $reminder->payment_status,
            'notes' => $reminder->notes,
            'attachments' => $reminder->attachments,
            'paid_at' => $reminder->paid_at ? $reminder->paid_at->toIso8601String() : null, // ✅ إضافة paid_at
            'created_at' => $reminder->created_at->toIso8601String(),
            'updated_at' => $reminder->updated_at->toIso8601String(),
            'housing' => $reminder->housing,
            'building' => $reminder->building,
        ]);
    }

    /**
     * Update reminder with new file uploads - FIXED VERSION
     */
    public function update(Request $request, $id)
    {
        $reminder = PaymentReminder::findOrFail($id);

        // ✅ تحويل payment_status من "1"/"0" إلى boolean
        $requestData = $request->all();
        
        if (isset($requestData['payment_status'])) {
            if ($requestData['payment_status'] === '1' || $requestData['payment_status'] === 'true') {
                $requestData['payment_status'] = true;
            } elseif ($requestData['payment_status'] === '0' || $requestData['payment_status'] === 'false') {
                $requestData['payment_status'] = false;
            }
        }

        $validator = Validator::make($requestData, [
            'housing_id'    => 'sometimes|exists:housings,id',
            'building_id'   => 'nullable|exists:buildings,id',
            'payment_type'  => 'sometimes|in:electricity,water,other',
            'due_date'      => 'sometimes|date',
            'amount'        => 'sometimes|numeric|min:0',
            'payment_status'=> 'sometimes|boolean',
            'notes'         => 'nullable|string',
            'attachments'   => 'nullable|array',
            'attachments.*' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx,xls,xlsx|max:5120',
            'delete_attachments' => 'nullable|array', // File names to delete
            'delete_attachments.*' => 'string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Invalid data',
                'errors' => $validator->errors()
            ], 422);
        }

        $validated = $validator->validated();

        // ✅ تحديث paid_at بناءً على payment_status
        if (isset($validated['payment_status'])) {
            if ($validated['payment_status'] === true && !$reminder->paid_at) {
                $validated['paid_at'] = now();
            } elseif ($validated['payment_status'] === false) {
                $validated['paid_at'] = null;
            }
        }

        // Delete specified files
        if (!empty($validated['delete_attachments'])) {
            $currentAttachments = $reminder->attachments ?? [];
            foreach ($validated['delete_attachments'] as $fileName) {
                $path = storage_path('app/public/attachments/' . $fileName);
                if (file_exists($path)) {
                    unlink($path);
                }
                // Remove from array
                $currentAttachments = array_diff($currentAttachments, [$fileName]);
            }
            $validated['attachments'] = array_values($currentAttachments); // Reindex keys
        }

        // Add new files
        $newAttachments = [];
        if ($request->hasFile('attachments')) {
            foreach ($request->file('attachments') as $file) {
                if ($file->isValid()) {
                    $fileName = 'attachment_' . time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                    $file->storeAs('public/attachments', $fileName);
                    $newAttachments[] = $fileName;
                }
            }
            
            // Merge new files with old ones
            $currentAttachments = $validated['attachments'] ?? ($reminder->attachments ?? []);
            $validated['attachments'] = array_merge($currentAttachments, $newAttachments);
        }

        $reminder->update($validated);

        // ✅ إرجاع البيانات مع الأنواع الصحيحة
        return response()->json([
            'message' => 'Reminder updated successfully',
            'data' => [
                'id' => (int) $reminder->id,
                'housing_id' => (int) $reminder->housing_id,
                'building_id' => $reminder->building_id ? (int) $reminder->building_id : null,
                'payment_type' => $reminder->payment_type,
                'due_date' => $reminder->due_date->format('Y-m-d'),
                'amount' => (float) $reminder->amount,
                'payment_status' => (bool) $reminder->payment_status,
                'notes' => $reminder->notes,
                'attachments' => $reminder->attachments,
                'paid_at' => $reminder->paid_at ? $reminder->paid_at->toIso8601String() : null, // ✅ إضافة paid_at
                'created_at' => $reminder->created_at->toIso8601String(),
                'updated_at' => $reminder->updated_at->toIso8601String(),
            ]
        ]);
    }

    /**
     * Delete reminder and its files
     */
    public function destroy($id)
    {
        $reminder = PaymentReminder::findOrFail($id);
        
        // Delete attached files first
        $reminder->deleteAttachments();
        
        // Delete the reminder
        $reminder->delete();

        return response()->json([
            'message' => 'Reminder and its files deleted successfully'
        ]);
    }

    /**
     * Download specific file
     */
    public function downloadAttachment($id, $fileName)
    {
        $reminder = PaymentReminder::findOrFail($id);
        
        if (!in_array($fileName, $reminder->attachments ?? [])) {
            return response()->json(['message' => 'File not found'], 404);
        }

        $path = storage_path('app/public/attachments/' . $fileName);
        
        if (!file_exists($path)) {
            return response()->json(['message' => 'File not found'], 404);
        }

        return response()->download($path, $fileName);
    }

    /**
     * Upload files separately (upload-only API)
     */
    public function uploadAttachments(Request $request, $id)
    {
        $reminder = PaymentReminder::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'attachments' => 'required|array',
            'attachments.*' => 'required|file|mimes:jpg,jpeg,png,pdf,doc,docx,xls,xlsx|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Invalid data',
                'errors' => $validator->errors()
            ], 422);
        }

        $newAttachments = [];
        foreach ($request->file('attachments') as $file) {
            if ($file->isValid()) {
                $fileName = 'attachment_' . time() . '_' . Str::random(10) . '.' . $file->getClientOriginalExtension();
                $file->storeAs('public/attachments', $fileName);
                $newAttachments[] = $fileName;
            }
        }

        // Merge new files with old ones
        $currentAttachments = $reminder->attachments ?? [];
        $reminder->attachments = array_merge($currentAttachments, $newAttachments);
        $reminder->save();

        return response()->json([
            'message' => 'Files uploaded successfully',
            'data' => $reminder
        ]);
    }

    /**
     * Delete files separately
     */
    public function deleteAttachments(Request $request, $id)
    {
        $reminder = PaymentReminder::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'file_names' => 'required|array',
            'file_names.*' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Invalid data',
                'errors' => $validator->errors()
            ], 422);
        }

        $currentAttachments = $reminder->attachments ?? [];
        foreach ($request->file_names as $fileName) {
            $path = storage_path('app/public/attachments/' . $fileName);
            if (file_exists($path)) {
                unlink($path);
            }
            // Remove from array
            $currentAttachments = array_diff($currentAttachments, [$fileName]);
        }

        $reminder->attachments = array_values($currentAttachments); // Reindex keys
        $reminder->save();

        return response()->json([
            'message' => 'Files deleted successfully',
            'data' => $reminder
        ]);
    }

    /**
     * Get all files for specific reminder
     */
    public function getAttachments($id)
    {
        $reminder = PaymentReminder::findOrFail($id);
        
        $attachments = [];
        if (!empty($reminder->attachments)) {
            foreach ($reminder->attachments as $fileName) {
                $attachments[] = [
                    'name' => $fileName,
                    'url' => asset('storage/attachments/' . $fileName),
                    'path' => storage_path('app/public/attachments/' . $fileName),
                ];
            }
        }

        return response()->json([
            'attachments' => $attachments
        ]);
    }

    /**
     * Get reminders by housing ID
     */
    public function getByHousing($housingId)
    {
        $reminders = PaymentReminder::with(['housing', 'building'])
            ->where('housing_id', $housingId)
            ->latest()
            ->get();
            
        return response()->json($reminders);
    }

    /**
     * Get reminders by payment status
     */
    public function getByStatus($status)
    {
        $validator = Validator::make(['status' => $status], [
            'status' => 'required|in:paid,unpaid,all'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Invalid status',
                'errors' => $validator->errors()
            ], 422);
        }

        $reminders = PaymentReminder::with(['housing', 'building']);
        
        if ($status == 'paid') {
            $reminders->where('payment_status', true);
        } elseif ($status == 'unpaid') {
            $reminders->where('payment_status', false);
        }
        
        $reminders = $reminders->latest()->get();

        return response()->json($reminders);
    }

    /**
     * Get reminders by date range
     */
    public function getByDateRange(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Invalid date range',
                'errors' => $validator->errors()
            ], 422);
        }

        $reminders = PaymentReminder::with(['housing', 'building'])
            ->whereBetween('due_date', [$request->start_date, $request->end_date])
            ->latest()
            ->get();

        return response()->json([
            'count' => $reminders->count(),
            'data' => $reminders
        ]);
    }

    /**
     * Mark reminder as paid
     */
    public function markAsPaid($id)
    {
        $reminder = PaymentReminder::findOrFail($id);
        
        $reminder->update([
            'payment_status' => true,
            'paid_at' => now()
        ]);

        return response()->json([
            'message' => 'Reminder marked as paid',
            'data' => $reminder
        ]);
    }

    /**
     * Mark reminder as unpaid
     */
    public function markAsUnpaid($id)
    {
        $reminder = PaymentReminder::findOrFail($id);
        
        $reminder->update([
            'payment_status' => false,
            'paid_at' => null
        ]);

        return response()->json([
            'message' => 'Reminder marked as unpaid',
            'data' => $reminder
        ]);
    }

    /**
     * Get statistics
     */
    public function statistics()
    {
        $totalReminders = PaymentReminder::count();
        $paidReminders = PaymentReminder::where('payment_status', true)->count();
        $unpaidReminders = PaymentReminder::where('payment_status', false)->count();
        
        $totalAmount = PaymentReminder::sum('amount');
        $paidAmount = PaymentReminder::where('payment_status', true)->sum('amount');
        $unpaidAmount = PaymentReminder::where('payment_status', false)->sum('amount');

        $paymentTypeStats = PaymentReminder::selectRaw('payment_type, COUNT(*) as count, SUM(amount) as total_amount')
            ->groupBy('payment_type')
            ->get();

        return response()->json([
            'counts' => [
                'total' => $totalReminders,
                'paid' => $paidReminders,
                'unpaid' => $unpaidReminders,
            ],
            'amounts' => [
                'total' => $totalAmount,
                'paid' => $paidAmount,
                'unpaid' => $unpaidAmount,
            ],
            'payment_type_stats' => $paymentTypeStats,
            'overdue_count' => PaymentReminder::where('due_date', '<', now())
                ->where('payment_status', false)
                ->count(),
        ]);
    }

    /**
     * Get paid reminders with paid_at date
     */
    public function getPaidRemindersWithDate()
    {
        $reminders = PaymentReminder::with(['housing', 'building'])
            ->where('payment_status', true)
            ->whereNotNull('paid_at')
            ->orderBy('paid_at', 'desc')
            ->get();

        return response()->json($reminders);
    }

    /**
     * Get unpaid reminders (without paid_at)
     */
    public function getUnpaidReminders()
    {
        $reminders = PaymentReminder::with(['housing', 'building'])
            ->where('payment_status', false)
            ->whereNull('paid_at')
            ->orderBy('due_date', 'asc')
            ->get();

        return response()->json($reminders);
    }

    /**
     * Get reminders due today
     */
    public function getDueToday()
    {
        $reminders = PaymentReminder::with(['housing', 'building'])
            ->whereDate('due_date', now()->toDateString())
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($reminders);
    }
}