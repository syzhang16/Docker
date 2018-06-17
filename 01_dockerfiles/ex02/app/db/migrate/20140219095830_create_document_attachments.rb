class CreateDocumentAttachments < ActiveRecord::Migration
  def up
    # Creation de la table regroupant les pieces-jointes des documents
    create_table :document_attachments do |t|
        t.integer :document_id
        t.attachment :attach
        t.timestamps
    end
  end

  def down
    # Suppression de la table "document_attachments"
    drop_table :document_attachments
  end
end
