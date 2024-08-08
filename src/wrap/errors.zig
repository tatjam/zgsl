// Errors are only used when emitting an error implies no useful information may be
// extracted, other than that involved by the error!
const GslError = error{ 
    Dom, 
    Range, 
    Fault, 
    InVal, 
    Failed, 
    Factor, 
    Sanity, 
    NoMem, 
    BadFunc, 
    RunAway, 
    MaxIter, 
    ZeroDiv, 
    Tol, 
    Underflow, 
    Overflow, 
    Loss, 
    Round, 
    BadLen, 
    NotSqr, 
    Sing, 
    Diverge, 
    Unsup, 
    Unimpl, 
    Cache, 
    Table, 
    NoProg, 
    NoProgJ, 
    TolF, 
    TolX, 
    TolG, 
    Eof };

const OverflowOrUnderflowError = error{
    Overflow,
    Underflow,
};
