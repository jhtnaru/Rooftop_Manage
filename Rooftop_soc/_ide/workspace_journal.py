# 2025-09-24T08:09:37.589034
import vitis

client = vitis.create_client()
client.set_workspace(path="Rooftop_soc")

platform = client.get_component(name="platform_rooftop_0")
status = platform.build()

comp = client.get_component(name="app_rooftop_0")
comp.build()

platform = client.get_component(name="platform_rooftop_2")
status = platform.build()

comp = client.get_component(name="app_rooftop_2")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

