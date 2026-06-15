class RenameRolesForFlatHierarchy < ActiveRecord::Migration[8.1]
  # 4 rôles -> 3 : superadmin->admin, admin->responsable. Ordre important.
  def up
    execute "UPDATE users SET role = 'responsable' WHERE role = 'admin'"
    execute "UPDATE users SET role = 'admin'       WHERE role = 'superadmin'"
  end

  # Reverse partiel (perte d'info sur l'origine des responsables).
  def down
    execute "UPDATE users SET role = 'superadmin' WHERE role = 'admin'"
    execute "UPDATE users SET role = 'admin'      WHERE role = 'responsable'"
  end
end
