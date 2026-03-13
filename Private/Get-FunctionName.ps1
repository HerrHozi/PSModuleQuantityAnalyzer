function Get-FunctionName {

    ################################################################################
    #####                                                                      ##### 
    #####    get function name for logging function                            #####
    #####                                                                      #####
    ################################################################################
    Param([int]$StackNumber = 1)
    #return [string]$(Get-PSCallStack)[$StackNumber].FunctionName

    return [string]$(Get-PSCallStack)[$StackNumber].FunctionName -replace '<.*?>',''
}
