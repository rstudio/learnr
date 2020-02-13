
## Comments
### 2020-02-12

I have addressed the extra parameter documentation and made other improvements to learnr.

Please let me know if there is anything I can do.

Thank you,
Barret

### 2020-02-03

Specifically, see the warnings about 'Documented arguments not in
\usage' in the r-devel checks.  These are from a recent bug fix
(PR#16223, see
<https://bugs.r-project.org/bugzilla/show_bug.cgi?id=16223>): can you
please fix your man pages as necessary?  (In most cases, remove the
documentation for argument '...'.)

Please correct before 2020-02-17 to safely retain your package on CRAN.

Best,
-k


## Test environments
* local OS X install, R 3.6.1
* GitHub Actions
  * ubuntu 16.04 - R 3.2, 3.3, 3.4, 3.5, 3.6.2
  * mac - 3.6.2
  * windows - 3.6.2, devel
* win-builder (oldrelease, release)
* R-hub - Windows Server 2008 R2 SP1, R-devel, 32/64 bit (devel)

I did not get an email response from win-builder devel.



## R CMD check results

0 errors ✔ | 0 warnings ✔ | 0 notes ✔


## revdepcheck results

We checked 4 reverse dependencies (3 from CRAN + 1 from BioConductor), comparing R CMD check results across CRAN and dev versions of this package.

* We saw 0 new problems
* We failed to check 0 packages
