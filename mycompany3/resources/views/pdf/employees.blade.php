<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 10px;
        }
        th, td {
            border: 1px solid #000;
            padding: 4px;
            text-align: left;
        }
    </style>
</head>
<body>

<h3>Employees – Page {{ $page }}</h3>

<table>
    <thead>
        <tr>
            <th>#</th>
            <th>Name</th>
            <th>Iqama</th>
            <th>Housing</th>
            <th>Building</th>
            <th>Room</th>
        </tr>
    </thead>
    <tbody>
        @foreach($employees as $i => $emp)
        <tr>
            <td>{{ $i + 1 }}</td>
            <td>{{ $emp->id_name }}</td>
            <td>{{ $emp->iqamah_number }}</td>
            <td>{{ optional($emp->housing)->name }}</td>
            <td>{{ optional($emp->building)->name }}</td>
            <td>{{ optional($emp->room)->name }}</td>
        </tr>
        @endforeach
    </tbody>
</table>

</body>
</html>
