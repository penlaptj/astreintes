class Service < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :slots, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Destinataires des e-mails « nouvelle astreinte disponible » pour ce service.
  def collaborators
    users.merge(User.active).where(role: "collaborateur")
  end

  # Valideurs : responsables du service + tous les admins.
  def managers
    User.active.where(id: users.where(role: "responsable").select(:id))
        .or(User.active.where(role: "admin"))
  end
end
