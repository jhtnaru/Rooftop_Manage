# 2025-09-21T15:33:06.511963
import vitis

client = vitis.create_client()
client.set_workspace(path="Rooftop_Manage")

platform = client.get_component(name="platform_rooftop")
status = platform.build()

comp = client.get_component(name="app_rooftop")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

