function Measure-PSFunctionLines {

    param(
        [Parameter(Mandatory)]
        $FunctionAst
    )

    $total = $FunctionAst.EndLine - $FunctionAst.StartLine + 1

    $lines = $FunctionAst.Ast.Extent.Text -split "\r?\n"

    $comment = ($lines | Where-Object { $_ -match '^\s*#' }).Count
    $blank = ($lines | Where-Object { $_ -match '^\s*$' }).Count
    $code = $total - $comment - $blank

    [PSCustomObject]@{
        TotalLines     = $total
        LinesOfCode    = $code
        LinesOfComment = $comment
    }
}