param([Parameter(Mandatory=$true)][string]$Port)
$serial = [System.IO.Ports.SerialPort]::new($Port,115200,'None',8,'One')
$serial.ReadTimeout = 2000
$serial.WriteTimeout = 2000
try {
    $serial.Open()
    $serial.DiscardInBuffer()
    foreach ($value in @(0,85,170,255,13,10)) {
        $bytes = [byte[]]@($value)
        $serial.Write($bytes,0,1)
        $actual = $serial.ReadByte()
        if ($actual -ne $value) { throw "UART: expected $value, received $actual" }
    }
    Write-Output "UART echo PASS on $Port (115200 8N1)"
} finally { $serial.Dispose() }
