package authz

default allow := false

scenario := data.scenarios[input.level]
user := scenario.users[input.user]
resource := scenario.resources[input.resource]

allow if {
    input.model == "rbac"
    allow_rbac
}

allow if {
    input.model == "abac"
    allow_abac
}

allow if {
    input.model == "rebac"
    allow_rebac
}

#
# Helper function
#

is_level4 if {
    input.level == "level4"
}

classification := object.get(resource, "classification", "yellow")

is_green if {
    classification == "green"
}

is_yellow if {
    classification == "yellow"
}

is_red if {
    classification == "red"
}

is_black if {
    classification == "black"
}

working_hours if {
    t := object.get(input, "time", "")
    t >= "09:00"
    t <= "17:00"
}

approved_location if {
    loc := object.get(input, "location", "")
    loc == "office"
}

#
# RBAC
#

# Green documents are readable by everyone
allow_rbac if {
    is_level4
    input.action == "read"
    is_green
}

allow_rbac if {
    input.action == "read"
    required_role := sprintf("viewer_%s", [resource.id])
    required_role in user.rbac_roles
}

allow_rbac if {
    input.action == "read"
    required_role := sprintf("editor_%s", [resource.id])
    required_role in user.rbac_roles
}

allow_rbac if {
    input.action == "write"
    required_role := sprintf("editor_%s", [resource.id])
    required_role in user.rbac_roles
}

allow_rbac if {
    input.action == "read"
    required_role := sprintf("manager_%s_read", [resource.id])
    required_role in user.rbac_roles
}

# Black documents require a very specific role plus context.
allow_rbac if {
    is_level4
    input.action == "read"
    is_black
    working_hours
    approved_location
    required_role := sprintf("black_%s_read_office_hours", [resource.id])
    required_role in user.rbac_roles
}

#
# ABAC
#

#
# Levels 1-3
#

allow_abac if {
    not is_level4
    input.action == "read"
    resource.project != null
    resource.project in user.managed_projects
    user.abac_role == "manager"
}

allow_abac if {
    not is_level4
    input.action == "read"
    resource.id in user.documents
    user.abac_role == "viewer"
}

allow_abac if {
    not is_level4
    input.action == "read"
    resource.id in user.documents
    user.abac_role == "editor"
}

allow_abac if {
    not is_level4
    input.action == "write"
    resource.id in user.documents
    user.abac_role == "editor"
}

allow_abac if {
    not is_level4
    input.action == "read"
    resource.project != null
    resource.project in user.projects
    user.abac_role == "viewer"
}

allow_abac if {
    not is_level4
    input.action == "read"
    resource.project != null
    resource.project in user.projects
    user.abac_role == "editor"
}

allow_abac if {
    not is_level4
    input.action == "write"
    resource.project != null
    resource.project in user.projects
    user.abac_role == "editor"
}

allow_abac if {
    is_level4
    input.action == "read"
    not is_black
    resource.id in user.documents
}

#
# Level 4
#

# Green: readable by all authenticated/known users
allow_abac if {
    is_level4
    input.action == "read"
    is_green
}

# Yellow: project members may read
allow_abac if {
    is_level4
    input.action == "read"
    is_yellow
    resource.project != null
    resource.project in user.projects
    user.abac_role == "viewer"
}

allow_abac if {
    is_level4
    input.action == "read"
    is_yellow
    resource.project != null
    resource.project in user.projects
    user.abac_role == "editor"
}

# Yellow: project editors may write
allow_abac if {
    is_level4
    input.action == "write"
    is_yellow
    resource.project != null
    resource.project in user.projects
    user.abac_role == "editor"
}

# Red: explicit document assignment required
allow_abac if {
    is_level4
    input.action == "read"
    is_red
    resource.id in user.documents
}

allow_abac if {
    is_level4
    input.action == "write"
    is_red
    resource.id in user.documents
    user.abac_role == "editor"
}

# Black: explicit assignment + time + location required
allow_abac if {
    is_level4
    input.action == "read"
    is_black
    resource.id in user.documents
    working_hours
    approved_location
}

allow_abac if {
    is_level4
    input.action == "write"
    is_black
    resource.id in user.documents
    user.abac_role == "editor"
    working_hours
    approved_location
}

# Managers may read yellow documents in managed projects
allow_abac if {
    is_level4
    input.action == "read"
    is_yellow
    resource.project != null
    resource.project in user.managed_projects
    user.abac_role == "manager"
}

#
# ReBAC
#

#
# Green documents are readable by everyone
#

allow_rebac if {
    is_level4
    input.action == "read"
    is_green
}

#
# Direct document access
#

allow_rebac if {
    not is_level4
    input.action == "read"
    user_in_document_viewer_relation(resource.id)
}

allow_rebac if {
    not is_level4
    input.action == "read"
    user_in_document_editor_relation(resource.id)
}

allow_rebac if {
    not is_level4
    input.action == "write"
    user_in_document_editor_relation(resource.id)
}

# Level 4 direct access for yellow/red
allow_rebac if {
    is_level4
    input.action == "read"
    not is_black
    user_in_document_viewer_relation(resource.id)
}

allow_rebac if {
    is_level4
    input.action == "read"
    not is_black
    user_in_document_editor_relation(resource.id)
}

allow_rebac if {
    is_level4
    input.action == "write"
    not is_black
    user_in_document_editor_relation(resource.id)
}

# Level 4 direct access for black requires time and location
allow_rebac if {
    is_level4
    input.action == "read"
    is_black
    working_hours
    approved_location
    user_in_document_viewer_relation(resource.id)
}

allow_rebac if {
    is_level4
    input.action == "read"
    is_black
    working_hours
    approved_location
    user_in_document_editor_relation(resource.id)
}

allow_rebac if {
    is_level4
    input.action == "write"
    is_black
    working_hours
    approved_location
    user_in_document_editor_relation(resource.id)
}

#
# Project-level for Levels 1-3
#

allow_rebac if {
    not is_level4
    input.action == "read"
    user_in_project_manager_relation(resource.project)
}

allow_rebac if {
    not is_level4
    input.action == "read"
    parent_project := scenario.relations.document_parent_project[resource.id]
    user_in_project_viewer_relation(parent_project)
}

allow_rebac if {
    not is_level4
    input.action == "read"
    parent_project := scenario.relations.document_parent_project[resource.id]
    user_in_project_editor_relation(parent_project)
}

allow_rebac if {
    not is_level4
    input.action == "write"
    parent_project := scenario.relations.document_parent_project[resource.id]
    user_in_project_editor_relation(parent_project)
}

#
# Level 4 inherited access
#

# Yellow documents inherit project viewer/editor access
allow_rebac if {
    is_level4
    input.action == "read"
    is_yellow
    parent_project := scenario.relations.document_parent_project[resource.id]
    user_in_project_viewer_relation(parent_project)
}

allow_rebac if {
    is_level4
    input.action == "read"
    is_yellow
    parent_project := scenario.relations.document_parent_project[resource.id]
    user_in_project_editor_relation(parent_project)
}

allow_rebac if {
    is_level4
    input.action == "write"
    is_yellow
    parent_project := scenario.relations.document_parent_project[resource.id]
    user_in_project_editor_relation(parent_project)
}

# Managers may read yellow documents in managed projects
allow_rebac if {
    is_level4
    input.action == "read"
    is_yellow
    user_in_project_manager_relation(resource.project)
}

#
# Relation helpers
#

user_in_document_viewer_relation(doc_id) if {
    viewers := object.get(scenario.relations.document_viewer, doc_id, [])
    input.user in viewers
}

user_in_document_editor_relation(doc_id) if {
    editors := object.get(scenario.relations.document_editor, doc_id, [])
    input.user in editors
}

user_in_project_viewer_relation(project_id) if {
    viewers := object.get(scenario.relations.project_viewer, project_id, [])
    input.user in viewers
}

user_in_project_editor_relation(project_id) if {
    editors := object.get(scenario.relations.project_editor, project_id, [])
    input.user in editors
}

user_in_project_manager_relation(project_id) if {
    managers := object.get(scenario.relations.project_manager, project_id, [])
    input.user in managers
}