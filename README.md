# OSF-meeting-setup

These scripts were used to batch-import/edit presentation-pages (via the OSF-API) for the [2019 OSF SPNHC meeting site](https://osf.io/view/SPNHC2019), and should be generalizable to any OSF meeting set-up. 

Input = CSV of submitted titles, abstracts, subject tags, author names & emails.

Each script loops through the CSV to do the following:

1. OSFsetup.R = format/collate submitted abstracts into separate PDFs
   - OSFpdfTemplate.Rmd = PDF template referenced by OSFsetup.R
2. OSFemail.R = submit (email) each submitted abstract to OSF
3. OSFtagID.R = retrieve node id's for OSF abstract pages (by title) add subject-tags and user-IDs (admins + contributors)
4. OSFusers.R = remove SPNHC admins from bibliographic contributors

5. OSFabstracts.R = retrieve OSF page titles & abstracts/wiki's
6. OSFdescripts.R = update descriptions of OSF projects
