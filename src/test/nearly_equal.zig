pub fn nearly_equal(T: type, a: []T, b: []T, eps: T) bool {
    for (a, b) |va, vb| {
        if (@abs(vb - va) > eps) {
            return false;
        }
    }
    return true;
}
