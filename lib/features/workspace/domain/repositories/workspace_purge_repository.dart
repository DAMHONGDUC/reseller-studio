/// Emptying a business without deleting it.
///
/// **Developer-only** — the one caller is the Delete all data card in
/// More → Settings, behind `devModeEnabledProvider`. It is the other half of
/// `DemoDataSeeder`: the seeder fills a real workspace so the app can be
/// demonstrated, and this takes it back to the empty state a new seller
/// actually opens, without the sign-out-and-make-another-business detour.
///
/// **The business itself survives, and so does everything that proves whose
/// it is.** Records go; the workspace row, its membership rows (hard rule 11)
/// and its audit log (hard rule 12) stay — `WorkspaceCollections.tableNames`
/// says which is which. Deleting the workspace is a different, owner-only
/// operation and lives on `WorkspaceRepository.deleteWorkspace`.
abstract interface class WorkspacePurgeRepository {
  /// Delete every business record in the open workspace, hard, returning how
  /// many rows went.
  ///
  /// **A hard delete, deliberately breaking hard rule 15's soft-delete.** A
  /// soft delete leaves the row joinable for the records pointing at it, which
  /// is the whole reason it exists — but nothing is left pointing at anything
  /// once the sweep finishes, and a workspace full of `deletedAt` rows is not
  /// the empty workspace this exists to reproduce.
  ///
  /// **Idempotent**: every step is a delete, so a second run returns 0 rather
  /// than failing on what is already gone.
  Future<int> deleteAllRecords();
}
