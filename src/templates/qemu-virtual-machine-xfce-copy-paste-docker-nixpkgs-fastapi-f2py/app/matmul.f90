! Classic double-precision matrix multiply: C = A * B
subroutine dgemm_simple(a, b, c, n)
  implicit none
  integer, intent(in) :: n
  double precision, intent(in), dimension(n,n) :: a
  double precision, intent(in), dimension(n,n) :: b
  double precision, intent(out), dimension(n,n) :: c
  integer :: i, j, k

  !f2py intent(in) n
  !f2py intent(in) a(n,n)
  !f2py intent(in) b(n,n)
  !f2py intent(out) c(n,n)

  c = 0.0d0
  do j = 1, n
    do k = 1, n
      do i = 1, n
        c(i,j) = c(i,j) + a(i,k) * b(k,j)
      end do
    end do
  end do
end subroutine dgemm_simple
